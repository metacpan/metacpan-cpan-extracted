package HTML::Template::Compiled::Plugin::I18N;

use strict;
use warnings;

our $VERSION = '1.04';

use Carp qw(croak);
use English qw(-no_match_vars $EVAL_ERROR);
use Hash::Util qw(lock_keys);
use Data::Dumper;
use HTML::Template::Compiled;
use HTML::Template::Compiled::Token;
use HTML::Template::Compiled::Plugin::I18N::DefaultTranslator;

our (%init, %escape_sub_of); ## no critic (PackageVars)

BEGIN {
    lock_keys(
        %init,
        qw(
            throw
            allow_maketext
            allow_gettext
            allow_formatter
            allow_unescaped
            translator_class
            escape_plugins
        ),
    );
}

sub _require_via_string {
    my $class = shift;

    eval "require $class" ## no critic (stringy eval)
        or _throw("Can not find package $class $EVAL_ERROR");

    return $class;
}

# class method
sub init {
    my ($class, %arg_of) = @_;

    # This escape plugins are already loaded.
    %escape_sub_of = (
        HTML     => \&HTML::Template::Compiled::Utils::escape_html,
        HTML_ALL => \&HTML::Template::Compiled::Utils::escape_html_all,
        URI      => \&HTML::Template::Compiled::Utils::escape_uri,
        JS       => \&HTML::Template::Compiled::Utils::escape_js,
        DUMP     => \&Dumper,
    );

    # Get the escape subs for each plugin ...
    my $escape_plugins = delete $arg_of{escape_plugins};
    if ($escape_plugins) {
        ref $escape_plugins eq 'ARRAY'
           or croak 'Parameter escape_plugins is not an array reference';
        for my $package ( @{$escape_plugins} ) {
            # register plugins
            my %escape = %{ _require_via_string($package)->register()->{escape} };
            SUB:
            for my $sub ( values %escape ) {
                # code ref given
                ref $sub eq 'CODE'
                    and next SUB;
                # sub name given
                no strict qw(refs); ## no critic (NoStrict)
                no warnings qw(redefine); ## no critic (NoWarnings)
                $sub = \&{$sub};
            }
            @escape_sub_of{ keys %escape } = values %escape;
        }
    }

    # ... and all the other boolenans and strings.
    my @keys = keys %arg_of;
    @init{@keys} = @arg_of{@keys};

    # Load the translator class.
    $init{translator_class} ||= 'HTML::Template::Compiled::Plugin::I18N::DefaultTranslator';
    _require_via_string($init{translator_class});

    # Register this plugin at HTC.
    HTML::Template::Compiled->register(__PACKAGE__);

    return $class;
}

# internal exception handler
sub _throw {
    my @message = @_;

    return
        ref $init{throw} eq 'CODE'
        ? $init{throw}->(@message)
        : croak @message;
}

# Register this plugin at HTC.
sub register {
    my ($class) = @_;

    return {
        # opening and closing tags to bind to
        tagnames => {
            HTML::Template::Compiled::Token::OPENING_TAG() => {
                TEXT => [
                    undef,
                    # attributes
                    qw(
                        NAME
                        VALUE
                        ESCAPE
                    ),
                    (
                        $init{allow_maketext}
                        ? qw(
                            _\d+
                            _\d+_VAR
                        )
                        : ()
                    ),
                    (
                        $init{allow_gettext}
                        ? qw(
                            PLURAL
                            PLURAL_VAR
                            COUNT
                            COUNT_VAR
                            CONTEXT
                            CONTEXT_VAR
                            _[A-Z][0-9A-Z_]*?
                            _[A-Z][0-9A-Z_]*?_VAR
                        )
                        : ()
                    ),
                    (
                        $init{allow_formatter}
                        ? qw(
                            FORMATTER
                        )
                        : ()
                    ),
                    (
                        $init{allow_unescaped}
                        ? qw(
                            UNESCAPED_[A-Z][0-9A-Z_]*?
                            UNESCAPED_[A-Z][0-9A-Z_]*?_VAR
                        )
                        : ()
                    ),
                ],
            },
        },
        compile => {
            # methods to compile to
            TEXT => {
                # on opening tab
                open => \&TEXT,
                # if you need closing, uncomment and implement method
                # close => \&close_text
            },
        },
    };
}

sub _lookup_variable {
    my ($htc, $var_name) = @_;

    return $htc->get_compiler()->parse_var(
        $htc,
        var            => $var_name,
        method_call    => $htc->method_call(),
        deref          => $htc->deref(),
        formatter_path => $htc->formatter_path(),
    );
}

sub _calculate_escape {
    my $arg_ref = shift;

    my @real_escapes;
    ESCAPE:
    for my $escape ( @{ $arg_ref->{escapes} } ) {
        # a '0' ignores all before
        if ($escape eq '0') {
            @real_escapes = ();
            next ESCAPE;
        }
        push @real_escapes, $escape;
    }
    # uc escape if no error
    my @unknown_escapes;
    ESCAPE:
    for my $escape (@real_escapes) {
        if ( exists $escape_sub_of{uc $escape} ) {
            $escape = uc $escape;
            next ESCAPE;
        }
        push @unknown_escapes, $escape;
    }
    # write back
    if ( exists $arg_ref->{escape_ref} ) {
        ${ $arg_ref->{escape_ref} } = \@real_escapes;
    }

    return @unknown_escapes ? \@unknown_escapes : ();
}

# Executes all needed escape subs.
sub _escape {
    my ($string, @escapes) = @_;

    @escapes
        or return $string;
    for (@escapes) {
        $string = $escape_sub_of{$_}->($string);
    }

    return $string;
}

# class method
sub escape {
    my (undef, $string, $escapes) = @_;

    return _escape($string, split m{,}xms, $escapes);
}

# class method
sub expand_unescaped {
    my (undef, $string, $arg_ref) = @_;

    my $regex = join q{|}, map { quotemeta $_ } keys %{$arg_ref};
    $string =~ s{
        \{ ($regex) \}
    }{
        defined $arg_ref->{$1} ? $arg_ref->{$1} : "{$1}"
    }xmsge;

    return $string;
}

# Prepare a string as Perl code.
sub _string_to_perl_code {
    my $string = shift;

    defined $string
        or return q{''};
    $string =~ s{\\}{\\}xmsg;
    $string =~ s{'}{\\'}xmsg;
    $string =~ s{"}{\\"}xmsg;

    return "'$string'";
}

# From here to subroutine TEXT: Caller is subroutine TEXT only.

sub _parse_attributes { ## no critic (ExcessComplexity)
    my ($attr_ref, $filename, $data_ref) = @_;

    my $package = __PACKAGE__;
    ATTRIBUTE:
    for my $name ( keys %{$attr_ref} ) {
        # parse ESCAPE
        if ($name eq 'ESCAPE') {
            if ( length $attr_ref->{$name} ) {
                $data_ref->{escape}->{array}
                    = [ split m{\|}xms, "0|$attr_ref->{$name}" ];
            }
        }
        if ( $init{allow_maketext} ) {
            # parse maketext placeholders
            # as string constant _1 .. _n
            # as variable _1_VAR .. _n_VAR
            my $is_maketext
                = my ($position, $is_variable)
                = $name =~ m{\A _ (\d+) (_VAR)? \z}xms;
            if ($is_maketext) {
                my $index = $position - 1;
                # _n, _n_VAR
                if ( exists $data_ref->{maketext}->{array}->[$index] ) {
                    _throw( qq{Error in template $filename, plugin $package. Can not use maktext position $position twice. $name="$attr_ref->{$name}"} );
                }
                $data_ref->{maketext}->{array}->[$index] = {
                    is_variable => $is_variable,
                    value       => $attr_ref->{$name},
                };
                next ATTRIBUTE;
            }
        }
        if ( $init{allow_gettext} ) {
            # parse gettext placeholders
            # as string constant _name_1 .. _name_n
            # as variable _name_1_VAR .. _name_n_VAR
            my $is_gettext
                = my ($key, $is_variable)
                = $name =~ m{\A _ ([A-Z][0-9A-Z_]*?) (_VAR)? \z}xms;
            if ($is_gettext) {
                # _name, _name_VAR
                if ( exists $data_ref->{gettext}->{hash}->{lc $key} ) {
                    _throw( qq{Error in template $filename, plugin $package. Can not use gettext key $key twice. $name="$attr_ref->{$name}"} );
                }
                $data_ref->{gettext}->{hash}->{lc $key} = {
                    is_variable => $is_variable,
                    value       => $attr_ref->{$name},
                };
                next ATTRIBUTE;
            }
            # parse gettext plural
            # as string constant PLURAL
            # as variable PLURAL_VAR
            my $is_plural
                = ($is_variable)
                = $name =~ m{\A PLURAL (_VAR)? \z}xms;
            if ($is_plural) {
                if ( exists $data_ref->{plural} ) {
                    _throw( qq{Error in template $filename, plugin $package. Can not use PLURAL/PLURAL_VAR twice. $name="$attr_ref->{$name}"} );
                }
                $data_ref->{plural} = {
                    is_variable => $is_variable,
                    value       => $attr_ref->{$name},
                };
                next ATTRIBUTE;
            }
            # parse gettext count
            # as string constant COUNT
            # as variable COUNT_VAR
            my $is_count
                = ($is_variable)
                = $name =~ m{\A COUNT (_VAR)? \z}xms;
            if ($is_count) {
                if ( exists $data_ref->{count} ) {
                    _throw( qq{Error in template $filename, plugin $package. Can not use COUNT/COUNT_VAR twice. $name="$attr_ref->{$name}"} );
                }
                $data_ref->{count} = {
                    is_variable => $is_variable,
                    value       => $attr_ref->{$name},
                };
                next ATTRIBUTE;
            }
            # parse gettext context
            # as string constant CONTEXT
            # as variable CONTEXT_VAR
            my $is_context
                = ($is_variable)
                = $name =~ m{\A CONTEXT (_VAR)? \z}xms;
            if ($is_context) {
                if ( exists $data_ref->{context} ) {
                    _throw( qq{Error in template $filename, plugin $package. Can not use CONTEXT/CONTEXT_VAR twice. $name="$attr_ref->{$name}"} );
                }
                $data_ref->{context} = {
                    is_variable => $is_variable,
                    value       => $attr_ref->{$name},
                };
                next ATTRIBUTE;
            }
        }
        if ( $init{allow_formatter} ) {
            # parse FORMATTER
            if ( $name eq 'FORMATTER' ) {
                if ( exists $data_ref->{formatter}->{array} ) {
                    _throw( qq{Error in template $filename, plugin $package. Can not use FORMATTER twice. $name="$attr_ref->{$name}"} );
                }
                $data_ref->{formatter}->{array} = [
                    map {
                        {value => $_};
                    } split m{\|}xms, $attr_ref->{$name}
                ];
                next ATTRIBUTE;
            }
        }
        if ( $init{allow_unescaped} ) {
            # parse unescaped placeholders
            # as string constant UNESCAPED_name_1 .. UNESCAPED_name_n
            # as variable UNESCAPED_name_1_VAR .. UNESCAPED_name_n_VAR
            my $is_unescaped
                = my ($key, $is_variable)
                = $name =~ m{\A UNESCAPED _ ([A-Z][0-9A-Z_]*?) (_VAR)? \z}xms;
            if ($is_unescaped) {
                # _name, _name_VAR
                if ( exists $data_ref->{unescaped}->{hash}->{lc $key} ) {
                    _throw( qq{Error in template $filename, plugin $package. Can not use unescaped key $key twice. $name="$attr_ref->{$name}"} );
                }
                $data_ref->{unescaped}->{hash}->{lc $key} = {
                    is_variable => $is_variable,
                    value       => $attr_ref->{$name},
                };
                next ATTRIBUTE;
            }
        }
    }
    # parse NAME/VALUE
    $data_ref->{text} = {
        exists $attr_ref->{NAME}
        ? (
            exists $attr_ref->{VALUE}
            ? _throw(
                qq{Error in template $filename, plugin $package. Do not use NAME and VALUE at the same time. NAME="$attr_ref->{NAME}" VALUE="$attr_ref->{VALUE}"}
            )
            : (
                is_variable => 1,
                value       => $attr_ref->{NAME},
            )
        )
        : (
            value => $attr_ref->{VALUE},
        )
    };

    return;
}

sub _check_escape {
    my ($data_ref, $htc, $filename) = @_;

    my $package = __PACKAGE__;
    my $unknown_escapes = _calculate_escape({
        escapes => [
            (
                split m{\|}xms, $htc->get_default_escape()
            ),
            (
                exists $data_ref->{escape}
                ? @{ $data_ref->{escape}->{array} }
                : ()
            ),
        ],
        escape_ref => \$data_ref->{escape}->{array},
    });
    if ($unknown_escapes) {
        my $escapes   = join ', ', @{$unknown_escapes};
        my $is_plural = @{$unknown_escapes} > 1;
        _throw(
            "Error in template $filename, plugin $package."
            . (
                $is_plural
                ? "Escapes $escapes at ESCAPE are unknown."
                : "Escape $escapes at ESCAPE is unknown."
            )
        );
    }
    if ( exists $data_ref->{escape} && ! @{ $data_ref->{escape}->{array} } ) {
        delete $data_ref->{escape};
    }

    return;
}

sub _prepare_htc_code {
    my ($data_ref, $htc) = @_;

    my $package = __PACKAGE__;

    # write code snippet
    my $to_perl_code = sub {
        my $data = shift;

        $data->{is_variable}
            and return _lookup_variable($htc, $data->{value});
        defined $data->{value}
            or return 'undef';

        return _string_to_perl_code( $data->{value} );
    };

    PREPARE_SCALAR:
    for my $key ( qw(filename text plural count context) ) {
        exists $data_ref->{$key}
            or next PREPARE_SCALAR;
        my $data = $data_ref->{$key};
        $data->{perl_code} = $to_perl_code->($data);
    }

    PREPARE_ARRAY:
    for my $key ( qw(maketext formatter) ) {
        exists $data_ref->{$key}
            or next PREPARE_ARRAY;
        my $data = $data_ref->{$key};
        $data->{perl_code}
            = q{[}
            . (
                join q{,}, map {
                    $to_perl_code->($_);
                } @{ $data->{array} }
            )
            . q{]};
    }

    PREPARE_HASH:
    for my $key ( qw(gettext unescaped) ) {
        exists $data_ref->{$key}
            or next PREPARE_HASH;
        my $data = $data_ref->{$key};
        $data->{perl_code}
            = q[{]
            . (
                join q{,}, map {
                    _string_to_perl_code($_)
                    . ' => '
                    . $to_perl_code->( $data->{hash}->{$_} )
                } keys %{ $data->{hash} }
            )
            . q[}];
    }

    # store escape itself
    PREPARE_JOINED_ARRAY:
    for my $key ( qw(escape) ) {
        exists $data_ref->{$key}
            or next PREPARE_JOINED_ARRAY;
        my $data = $data_ref->{$key};
        $data->{perl_code}
            = _string_to_perl_code(
                join q{,}, @{ $data->{array} }
        );
    }

    return;
}

sub TEXT {
    my ($htc, $token, $arg_ref) = @_;

    my $attr_ref = $token->get_attributes();
    my $filename = $htc->get_filename();

    my %data = (
        filename => {
            value => $filename,
        },
    );
    _parse_attributes($attr_ref, $filename, \%data);
    _check_escape(\%data, $htc, $filename);
    _prepare_htc_code(\%data, $htc);

    # necessary for HTC's caching mechanism
    my $inner_hash = join ', ', map {
        ( $_ eq 'filename' || exists $data{$_} )
        ? "$_ => $data{$_}->{perl_code}"
        : ();
    } keys %data;

    return <<"EO_CODE";
$arg_ref->{out} $init{translator_class}->translate({$inner_hash});
EO_CODE
}

1;

__END__

=pod

=head1 NAME

HTML::Template::Compiled::Plugin::I18N - Internationalization for HTC

$Id: I18N.pm 180 2010-10-29 19:44:26Z steffenw $

$HeadURL: https://htc-plugin-i18n.svn.sourceforge.net/svnroot/htc-plugin-i18n/trunk/lib/HTML/Template/Compiled/Plugin/I18N.pm $

=head1 VERSION

1.04

=head1 SYNOPSIS

=head2 Initialize the plugin and then the template

    use HTML::Template::Compiled;
    use HTML::Template::Compiled::Plugin::I18N;

    HTML::Template::Compiled::Plugin::I18N->init(
        # All parameters are optional.
        escape_plugins => [ qw(
            HTML::Template::Compiled::Plugins::ExampleEscape
        ) ],
        # At first write this not. Use the default translator.
        translator_class => 'MyProjectTranslator',
    );

    my $htc = HTML::Template::Compiled->new(
        plugin    => [ qw(
            HTML::Template::Compiled::Plugin::I18N
            HTML::Template::Compiled::Plugin::ExampleEscape
        ) ],
        scalarref => \'<%TEXT VALUE="Hello World!" %>',
    );
    print $htc->output();

=head2 Create a Translator class

This translator class replaces the default translator.

    package MyProjectTranslator;

    use HTML::Template::Compiled::Plugin::I18N;

    sub translate {
        my ($class, $arg_ref) = @_;

        # Translate the 'text'.
        # If maketext is allowed, replace the 'maketext' placeholders.
        # Alternative, if gettext is allowed, translate 'text' and 'plural'
        # and replace the 'gettext' palceholders.
        my $translation
            = your_translator( $arg_ref->{text}, ... );

        # Escape the translated string now.
        if ( exists $arg_ref->{escape} ) {
            $translation = HTML::Template::Compiled::Plugin::I18N->escape(
                $translation,
                $params->{escape},
            );
        }

        # If formatters are allowed, run the formatters like Markdown.
        if ( exists $arg_ref->{formatter} ) {
            my $formatter_ref = $arg_ref->{formatter};
            for my $formatter ( @{$formatter_ref} ) {
                # Call here a formatter like Markdown
                if (lc $formatter eq lc 'Markdown') {
                    # $translation = ... $tanslation;
                }
            }
        }

        # If unescaped is allowed, replace at least the unescaped placholders.
        if ( exists $arg_ref->{unescaped} ) {
            $translation = HTML::Template::Compiled::Plugin::I18N->expand_unescaped(
                $translation,
                $arg_ref->{unescaped},
            );
        }

        return $translation;
    }

=head1 DESCRIPTION

The Plugin allows you to create multilingual templates
including maketext and/or gettext features.

Before you have written your own translator class,
HTML::Template::Compiled::I18N::DefaultTranslator runs.

Later you have to write a translator class
to join the plugin to your selected translation module.

=head1 TEMPLATE SYNTAX

=head2 Escape

An escape can be a "0" to ignore all inherited escapes.
It can be a single word like "HTML"
or a list concatinated by "|" like "HTML|BR".

=over

=item * Without escape

    <%TEXT ... %>         (if no default escape is set)
    <%TEXT ... ESCAPE=0%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        ...
    }

=item * Escape HTML as example

    <%TEXT ... %>            (default escape is set)
    <%TEXT ... ESCAPE=HTML%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        escape => 'HTML',
        ...
    }

=item * More than one escape

    <%TEXT ... ESCAPE=HTML|BR%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        escape => 'HTML|BR',
        ...
    }

=back

=head2 VALUE or NAME

=over

=item * Static text values

    <%TEXT VALUE="some static text"%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        text   => 'some staic text',
        ...
    }

=item * Text from a variable

    <%TEXT a.var%>
    <%TEXT NAME="a.var"%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        text => $a->var(), # or $a->{var}
        ...
    }

=back

=head2 Locale::Maketext placeholders

Allow maketext during initialization.

    HTML::Template::Compiled::Plugin::I18N->init(
        allow_maketext => $true_value,
        ...
    );

=over

=item * With a static value

    <%TEXT VALUE="Hello [_1]!" _1="world"%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        text     => 'Hello [_1]!',
        maketext => [ qw( world ) ],
    }

=item * With a variable

    <%TEXT VALUE="Hello [_1]!" _1_VAR="var.with.the.value"%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        text     => 'Hello [_1]!',
        maketext => [ $var->with()->the()->value() ], # or $var->{with}->{the}->{value}
    }

=item * Mixed samples

    <%TEXT VALUE="The [_1] is [_2]." _1="window" _2="blue" %>
    <%TEXT a.text                    _1="window" _2_VAR="var.color" %>

=back

=head2 Locale::TextDomain placeholders

Allow gettext during initialization.

    HTML::Template::Compiled::Plugin::I18N->init(
        allow_gettext => $true_value,
        ...
    );

=over

=item * With a static value

    <%TEXT VALUE="Hello {name}!" _name="world"%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        text    => 'Hello {name}!',
        gettext => { name => 'world' },
    }

=item * With a variable

    <%TEXT VALUE="Hello {name}!" _name_VAR="var.with.the.value"%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        text    => 'Hello {name}!',
        gettext => { name => $var->with()->the()->value() },
    }

=item * Plural forms with PLURAL, PLURAL_VAR, COUNT COUNT_VAR

    <%TEXT VALUE="book" PLURAL="books" COUNT="1"%>
    <%TEXT VALUE="book" PLURAL="books" COUNT_VAR="var.num"%>
    <%TEXT VALUE="{num} book" PLURAL="{num} books" COUNT="2" _num="2"%>

For the last one,
the 2nd parameter of the method translate (translator class) will set to:

    {
        text    => '{num} book',
        plural  => '{num} books',
        count   => 2,
        gettext => { num => 2 },
    }

=back

=head2 Formatter

Allow formatter during initialization.

    HTML::Template::Compiled::Plugin::I18N->init(
        allow_formatter => $true_value,
        ...
    );

=over

=item * One formatter

   <%TEXT VALUE="some **marked** text" FORMATTER="markdown"%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        text      => 'some **marked** text',
        formatter => [qw( markdown )],
    }

=item * More formatters

   <%TEXT VALUE="some **marked** text" FORMATTER="markdown|second"%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        text      => 'some **marked** text',
        formatter => [qw( markdown second)],
    }

=back

=head2 Unescaped placeholders

Unescaped placeholders are written in the text like gettext placeholders.
They are usable allone or in combination with maketext or gettext placeholders.

Allow unescaped placeholders during initialization.

    HTML::Template::Compiled::Plugin::I18N->init(
        allow_unescaped => $true_value,
        ...
    );

=over

=item * With a static value

    <%TEXT VALUE="Hello" UNESCAPED_link_begin='<a href="...">' UNESCAPED_link_end='</a>'%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        text      => 'Hello',
        unescaped => {
            link_begin => '<a href="...">',
            link_end   => '</a>',
        },
    }

=item * With a variable

    <%TEXT VALUE="Hello" UNESCAPED_link_begin_VAR="var1" UNESCAPED_link_end_VAR="var2"%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        text    => 'Hello {name}!',
        gettext => {
            var1 => $var1,
            var2 => $var2,
        },
    }

=back

=head1 EXAMPLE

Inside of this Distribution is a directory named example.
Run this *.pl files.

=head1 SUBROUTINES/METHODS

=head2 Class method init

Call init before the HTML::Template::Compiled->new(...) will called.

    # all parameters are optional
    HTML::Template::Compiled::Plugin::I18N->init(
        throw            => sub {
            croak @_; # this is the default
        }
        allow_maketext   => $boolean,
        allow_gettext    => $boolean,
        allow_formatter  => $boolean,
        allow_unescaped  => $boolean,
        translator_class => 'TranslatorClassName',
        escape_plugins   => [ qw(
            the same like
            HTML::Template::Compiled->new(plugin => [qw( ...
            but escape plugins only
        )],
    );

=head2 Class method register

HTML::Template::Compiled will call this method to register this plugin.

    HTML::Template::Compiled::Plugin::I18N->register();

=head2 Class method escape

    $escaped_string = HTML::Template::Compiled::Plugin::I18N->escape(
        $translated_string,
        $escapes_joined_by_comma,
    );

=head2 Class method expand_unescaped

    $finished_string = HTML::Template::Compiled::Plugin::I18N->expand_unescaped(
        $translated_and_escaped_string,
        $hash_ref_with_placeholders,
    );

=head2 Subroutine TEXT and swapt out code

=over

=item * Subroutine _parse_attributes

=item * Subroutine _check_escape {

=item * Subroutine _prepare_htc_code {

=item * Subroutine TEXT

Do not call this method.
It is used to create the HTC Template Code.
This method is used as callback
which is registerd to HTML::Template::Compiled by our register method.

It calls the translate method of the Translator class 'TranslatorClassNames'.

The translate method will called like

    $translated = TranslatorClass->new()->translate({
        text => 'result of variable lookup or VALUE',
        ...
    });

=back

=head1 DIAGNOSTICS

=over

=item * Missing escape plugin or translator class

Can not find package ...

=back

=head2 Text

=over

=item * Select NAME or VALUE

Error in template filename, plugin package.
Do not use NAME and VALUE at the same time.
NAME="..."
VALUE="..."

=item * Escape plugin is not configured at method init

Error in template filename, plugin package.
Escape ... at ESCAPE is unknown.

=back

=head2 Maketext

=over

=item * Double maketext placeholder

Error in template filename, plugin package.
Can not use maktext position n twice.
_n="..."

=back

=head2 Gettext

=over

=item * Ddouble gettext palaceholder

Error in template filename, plugin package.
Can not use gettext key name twice.
_name="..."

=item * Double gettext plural

Error in template filename, plugin package.
Can not use PLURAL/PLURAL_VAR twice.
PLURAL="..."

or

Error in template filename, plugin package.
Can not use PLURAL/PLURAL_VAR twice.
PLURAL_VAR="..."

=item * Double gettext count

Error in template filename, plugin package.
Can not use COUNT/COUNT_VAR twice.
COUNT="..."

or

Error in template filename, plugin package.
Can not use COUNT/COUNT_VAR twice.
COUNT_VAR="..."

=item * Double gettext context

Error in template filename, plugin package.
Can not use CONTEXT/CONTEXT_VAR twice.
CONTEXT="..."

or

Error in template filename, plugin package.
Can not use CONTEXT/CONTEXT_VAR twice.
CONTEXT_VAR="..."

=item * Double formatter

Error in template filename, plugin package.
Can not use FORMATTER twice.
FORMATTER="..."

=back

=head1 CONFIGURATION AND ENVIRONMENT

Call init method before HTML::Template::Compiled->new(...).

=head1 DEPENDENCIES

Carp

English

L<Hash::Util|Hash::Util>

L<Data::Dumper|Data::Dumper>

L<HTML::Template::Compiled|HTML::Template::Compiled>

L<HTML::Template::Compiled::Token|HTML::Template::Compiled::Token>

L<HTML::Template::Compiled::I18N::DefaultTranslator|HTML::Template::Compiled::I18N::DefaultTranslator>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 SEE ALSO

L<HTML::Template::Compiled|HTML::Template::Compiled>

L<Hyper::Template::Plugin::Text|Hyper::Template::Plugin::Text>
This was the idea for this module.
This can not support escape.
This can not handle gettext.
The module is too Hyper-ish and not for common use.

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 - 2010,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
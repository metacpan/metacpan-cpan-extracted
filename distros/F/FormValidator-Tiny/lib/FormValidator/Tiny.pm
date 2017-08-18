package FormValidator::Tiny;
$FormValidator::Tiny::VERSION = '0.004';
use v5.18;
use warnings;

use List::Util qw( any pairs pairgrep pairmap );
use Scalar::Util qw( blessed looks_like_number );
use experimental qw( regex_sets );

use Exporter;

BEGIN {
    our @ISA = qw( Exporter );
    our @EXPORT = qw( validation_spec validate_form );
    my @export_predicates = qw(
        limit_character_set
        length_in_range
        equal_to
        number_in_range
        one_of
    );
    my @export_filters = qw(
        split_by
        trim
    );
    our @EXPORT_OK = (@export_predicates, @export_filters);
    our %EXPORT_TAGS = (
        validation => \@EXPORT,
        predicates => \@export_predicates,
        filters    => \@export_filters,
        all        => [ @EXPORT, @export_predicates, @export_filters ],
    );
}

# ABSTRACT: A tiny form validator

my %coercer = (
    '+'     => sub { (1, '', 0+$_[0]) },
    '?'     => sub { (1, '', length($_[0]) > 0) },
    '?+'    => sub { (1, '', !!(0+$_[0])) },
    '?perl' => sub { (1, '', !!$_[0]) },
    '[]'    => sub { (1, '', [ _listy($_[0]) ]) },
    '{}'    => sub { (1, '', ref $_[0] ? +{ _listy($_[0]) } : { $_[0] => $_[0] })  },
);

sub _sub_coercer {
    my ($sub) = @_;
    sub {
        local $_ = $_[0];
        my $into = $sub->(@_);
        (1, '', $into);
    }
}

sub _yes_no_coercer {
    my ($yes, $no) = @_;
    my $fcyes = fc $yes;
    my $fcno  = fc $no;
    sub {
        my $fc_ = fc $_[0];
        my $truth = $fc_ eq $fcyes ? 1
                  : $fc_ eq $fcno  ? 0
                  :                  undef;

        return (defined $truth, qq[Enter "$yes" or "$no".], $truth);
    };
}

sub _package_coercer {
    my ($package) = @_;
    sub { (1, '', $package->new($_[0])) }
}

sub _type_coercer {
    my ($type) = @_;
    sub { (1, '', $type->coerce($_[0])) }
}

sub _sub_validator {
    my ($sub) = @_;
    sub {
        return (1, '', $_[0]) unless defined $_[0];
        local $_ = $_[0];
        my ($valid, $error) = $sub->(@_);
        ($valid, $error, $_[0]);
    };
}

sub _re_validator {
    my ($re) = @_;
    sub {
        my ($value) = @_;
        return (1, '', $value) unless defined $value;
        my $valid = $value =~ /$re/;
        ($valid, 'Incorrect.', $value);
    };
}

sub _type_validator {
    my ($type) = @_;
    if ($type->can('check')) {
        my $message = $type->can('get_message') ? sub { $type->get_message($_[0]) }
                    :                             'Incorrect.';

        return sub {
            my ($value) = @_;
            return (1, '', $value) unless defined $value;
            my $valid = $type->check($value);
            ($valid, $message, $value);
        }
    }
    elsif ($type->can('validate')) {
        return sub {
            my ($value) = @_;
            return (1, '', $value) unless defined $value;
            my $message = $type->validate($value);
            (!defined $message, $message//'', $value);
        }
    }

    die "bad type encountered"; # uncoverable statement
}

sub _with_error {
    my ($decl, $with_error) = @_;
    sub {
        my ($valid, $decl_message, $value) = $decl->(@_);
        ($valid, $with_error, $value);
    }
}

sub _listy {
    my ($stuff) = @_;
    return @$stuff if 'ARRAY' eq ref $stuff;
    return %$stuff if 'HASH'  eq ref $stuff;
    return ($stuff);
}

sub _ytsil {
    my ($old_stuff, $new_stuff) = @_;
    return $new_stuff      if 'ARRAY' eq ref $old_stuff;
    return { @$new_stuff } if 'HASH'  eq ref $old_stuff;
    return $new_stuff->[0];
}

sub _for_each {
    my ($element, $decl_sub) = @_;

    my $lister = $element eq 'each' ? sub { _listy($_[0]) } : sub { pairs(_listy($_[0])) };

    my ($puller, $pusher);
    if ($element eq 'key') {
        $puller = sub { $_[0][0] };          # pull key from pairs()
        $pusher = sub { ($_[1], $_[0][1]) }; # push updated key, original value from pairs()
    }
    elsif ($element eq 'value') {
        $puller = sub { $_[0][1] };          # pull value from pairs()
        $pusher = sub { ($_[0][0], $_[1]) }; # push original key from pairs(), updated value
    }
    else { # $element eq 'each'
        $puller = sub { $_[0] };             # pull value from _listy()
        $pusher = sub { $_[1] };             # push updated element
    }

    sub {
        my ($stuff) = @_;

        my $valid = 1;
        my $error = '';
        my @new_stuff = map {
            my $update_value = $puller->($_);
            my ($element_valid, $element_error, $element_value) = $decl_sub->($update_value);
            unless ($element_valid) {
                $valid   = 0;
                $error ||= $element_error;
            }
            $pusher->($_, $element_value);
        } $lister->($stuff);

        return ($valid, $error, _ytsil($stuff, \@new_stuff));
    }
}

# lifted from perldoc perldata
my $NAME_RE = qr/ (?[ ( \p{Word} & \p{XID_Start} ) + [_] ])
                  (?[ ( \p{Word} & \p{XID_Continue} ) ]) *    /x;
my $PACKAGE_RE = qr/^ $NAME_RE (?: ('|::) $NAME_RE )* $/x;

sub _locate_package_name {
    my ($spec_name, $depth) = @_;
    $depth //= 1;

    die "name must be a valid Perl identifier"
        unless $spec_name =~ /$PACKAGE_RE/;

    my ($package, $name);
    if ($spec_name =~ /\b(::|')\b/) {
        my @parts = split /::|'/, $spec_name;
        $name = pop @parts;
        $package = join '::', @parts;
    }
    else {
        ($package) = caller($depth);
        $package //='main';
        $name      = $spec_name;
    }

    $package .= '::FORM_VALIDATOR_TINY_SPECIFICATION';
    {
        no strict 'refs';
        ${ $package } //= {};
    }

    ($package, $name);
}

sub validation_spec($;$) {
    my ($name, $spec) = @_;
    if (ref $name) {
        $spec = $name;
        undef $name;
    }

    my $error;
    if (defined $name) {
        $error = sub { die "spec [$name] ", @_ };
    }
    else {
        if (!defined wantarray) {
            die "useless call to validation_spec with no name in void context";
        }
        $error = sub { die "spec ", @_ };
    }

    $error->("must be an array reference")
        unless 'ARRAY' eq ref $spec;

    $error->("contains odd number of elements")
        unless scalar @$spec % 2 == 0;

    my @decl_spec;
    my %encountered_fields;
    for my $field_pair (pairs @$spec) {
        my ($field, $decls) = @$field_pair;

        my $error = sub { $error->("input declaration for [$field] ", @_) };

        $error->("has been defined twice") if $encountered_fields{ $field };
        $encountered_fields{ $field }++;

        $error->("must be in an array reference")
            unless 'ARRAY' eq ref $decls;

        $error->("contains odd number of elements")
            unless scalar @$decls % 2 == 0;

        my %options;
        my @decl = (\%options);
        for my $decl_pair (pairs @$decls) {
            my ($op, $arg) = @$decl_pair;

            if (any { $op eq $_ } qw( from multiple trim )) {
                $error->("found [$op] after filter or validation declarations")
                    if @decl > 1;

                $error->("has more than one [$op] declaration")
                    if defined $options{ $op };

                $options{ $op } = $arg;
            }

            elsif ($op =~ /^ (?: (each|key|value)_ )? into $/x) {
                my $element = $1;

                my $into_sub;
                if ('CODE' eq ref $arg) {
                    $into_sub = _sub_coercer($arg);
                }
                elsif (blessed $arg && $arg->can('coerce')) {
                    $into_sub = _type_coercer($arg);
                }
                elsif (defined $coercer{ $arg }) {
                    $into_sub = $coercer{ $arg };
                }
                elsif ($arg =~ /\?([^!]+)!(.+)/) {
                    $into_sub = _yes_no_coercer($1, $2);
                }
                elsif ($arg =~ $PACKAGE_RE) {
                    $into_sub = _package_coercer($arg);
                }
                else {
                    $error->("has unknown [$op] declaration argument [$arg]");
                }

                $into_sub = _for_each($element, $into_sub) if $element;
                push @decl, $into_sub;
            }

            elsif ($op eq 'required' || $op eq 'optional') {
                $arg = !$arg if $op eq 'optional';

                # Validate on required
                if ($arg) {
                    push @decl, sub {
                        my $valid = (defined $_[0] && $_[0] =~ /./);
                        ($valid, 'Required.', $_[0])
                    };
                }

                # Shortcircuit on optional
                else {
                    push @decl, sub {
                        my $valid = (defined $_[0] && $_[0] =~ /./) ? 1 : undef;
                        ($valid, '', $_[0])
                    };
                }
            }

            elsif ($op =~ /^ (?: (each|key|value)_ )? must $/x) {
                my $element = $1;

                my $must_sub;
                if ('CODE' eq ref $arg) {
                    $must_sub = _sub_validator($arg);
                }
                elsif ('Regexp' eq ref $arg) {
                    $must_sub = _re_validator($arg);
                }
                elsif (blessed $arg && ($arg->can('check') || $arg->can('validate'))) {
                    $must_sub = _type_validator($arg);
                }
                else {
                    $error->("has unknown [$op] declaration argument [$arg]");
                }

                $must_sub = _for_each($element, $must_sub) if $element;
                push @decl, $must_sub;
            }

            elsif ($op eq 'with_error') {
                $error->("has [$op] before a declaration in which it may modify")
                    unless @decl > 1;

                my $last_decl = pop @decl;
                push @decl, _with_error($last_decl, $arg);
            }

            else {
                $error->("has unknown [$op]");
            }
        }

        push @decl_spec, $field, \@decl;
    }

    my $finished_spec = \@decl_spec;
    bless $finished_spec, __PACKAGE__;

    if (defined $name) {
        my $package;
        ($package, $name) = _locate_package_name($name);

        {
            no strict 'refs';
            ${ $package }->{ $name } = $finished_spec;
        }
    }

    return $finished_spec;
}

sub validate_form($$) {
    my ($name, $input) = @_;
    my @input;
    if (blessed $input && $input->can('flatten')) {
        @input = $input->flatten;
    }
    else {
        @input = _listy($input);
    }

    my $spec = $name;
    unless (blessed $spec && $spec->isa(__PACKAGE__)) {
        my $package;
        ($package, $name) = _locate_package_name($name);

        {
            no strict 'refs';
            $spec = ${ $package }->{ $name };

            die "no spec with name [$name] found in package [$package]"
                unless defined $spec;
        }
    }

    die "no spec provided to validate with" unless defined $spec;

    my (%params, %errors);
    FIELD: for my $field_pair (pairs @$spec) {
        my ($field, $decls) = @$field_pair;

        my $field_input;
        DECL_FOR_FIELD: for my $decl (@$decls) {
            if ('HASH' eq ref $decl) {
                my $from     = $decl->{from}     // $field;
                my $multiple = $decl->{multiple} // 0;
                my $trim     = $decl->{trim}     // 1;

                my @values = pairmap { $b } pairgrep { $a eq $from } @input;
                @values = map { if (defined) { s/^\s+//; s/\s+$// } $_ } @values if $trim;

                if ($multiple) {
                    $field_input = \@values;
                }
                else {
                    $field_input = pop @values;
                }
            }

            else {
                my ($valid, $error, $new_value) = $decl->($field_input, \%params);

                if (!defined $valid) {
                    $field_input = undef;
                    last DECL_FOR_FIELD;
                }
                elsif ($valid) {
                    $field_input = $new_value;
                }
                else {
                    $field_input = undef;
                    push @{ $errors{ $field } }, $error;
                    last DECL_FOR_FIELD;
                }
            }
        }

        $params{ $field } = $field_input;
    }

    my $errors = scalar keys %errors ? \%errors : undef;
    return (\%params, $errors);
}

sub _comma_and {
    if (@_ == 0) {
        return '';
    }
    elsif (@_ == 1) {
        return $_[0];
    }
    elsif (@_ == 2) {
        return "$_[0] and $_[1]";
    }
    else {
        my $last = pop @_;
        return join(", ", @_) . ", and " . $last
    }
}

sub limit_character_set {
    my $_build_class = sub {
        my @class_parts = map {
            if (1 == length $_) {
                [ "[$_]", qq["$_"] ]
            }
            elsif (/^(.)-(.)$/ && ord($1) < ord($2)) {
                [ "[$_]", qq["$1" through "$2"] ]
            }
            elsif (/^\[([^\]]+)\]$/) {
                my $name = my $prop = $1;
                $name =~ s/_/ /g;
                [ "\\p{$prop}", qq[\L$name\E characters] ]
            }
            else {
                die "invalid character set [$_]";
            }
        } @_;

        my $classes = join ' + ', map { $_->[0] } @class_parts;
        my $re = qr/(?[ $classes ])/x;

        my $error = _comma_and(map { $_->[1] } @class_parts);

        return ($re, $error);
    };

    if (@_ == 2 && 'ARRAY' eq ref $_[0] && 'ARRAY' eq ref $_[1]) {
        my ($first_re, $first_error) = $_build_class->(@{ $_[0] });
        my ($rest_re, $rest_error)   = $_build_class->(@{ $_[1] });

        my $error = "First character only permits: "
                  . $first_error . ". Remaining only permits: "
                  . $rest_error;

        sub {
            my ($value) = @_;
            my $valid = ($value =~ /^(?:$first_re$rest_re*)?$/);
            ($valid, $error);
        };
    }
    else {
        my ($re, $error) = $_build_class->(@_);

        $error = "Only permits: "
               . $error;

        sub {
            my ($value) = @_;
            my $valid = ($value =~ /^$re*$/);
            ($valid, $error);
        };
    }
}

sub length_in_range {
    my ($start, $stop) = @_;

    die "minimum length in length_in_range must be a positive integer, got [$start] instead"
        unless $start =~ /^(?:[0-9]+|\*)$/;

    die "maximum length in length_in_range must be a positive integer, got [$stop] instead"
        unless $stop =~ /^(?:[0-9]+|\*)$/;

    die "minimum length must be less than or equal to maximum length in length_in_range, got [$start>$stop] instead"
        if $start ne '*' && $stop ne '*' && $start > $stop;

    if ($start eq '*' && $stop eq '*') {
        return sub { (1, '') };
    }
    elsif ($start eq '*') {
        return sub {
            my $valid = length $_[0] <= $stop;
            ($valid, "Must be no longer than $stop characters.")
        };
    }
    elsif ($stop eq '*') {
        return sub {
            my $valid = length $_[0] >= $start;
            ($valid, "Must be at least $start characters long.")
        }
    }
    else {
        return sub {
            return (1, '') unless defined $_[0];
            if (length $_[0] >= $start) {
                my $valid = length $_[0] <= $stop;
                return ($valid, "Must be no longer than $stop characters.");
            }
            else {
                return ('', "Must be at least $start characters in length.")
            }
        }
    }
}

sub equal_to {
    my ($field_name) = @_;

    sub {
        ($_[0] eq $_[1]{ $field_name }, "The value must match $field_name.")
    }
}

sub number_in_range {
    my $start = shift;
    my $stop  = shift;
    my $starti = 1;
    my $stopi  = 1;

    if ($start eq 'exclusive') {
        $starti = 0;
        $start  = $stop;
        $stop   = shift;
    }

    if ($stop eq 'exclusive') {
        $stopi = 0;
        $stop  = shift;
    }

    die "minimum length in length_in_range must be a positive integer, got [$start] instead"
        unless $start eq '*' || looks_like_number($start);

    die "maximum length in length_in_range must be a positive integer, got [$stop] instead"
        unless $stop eq '*' || looks_like_number($stop);

    die "minimum length must be less than or equal to maximum length in length_in_range, got [$start>$stop] instead"
        if $start ne '*' && $stop ne '*' && $start > $stop;

    my $check_start = $starti ? sub { (($_[0] >= $start), "Number must be at least $start.") }
                    :           sub { (($_[0] > $start),  "Number must be greater than $start.") };
    my $check_stop  = $stopi  ? sub { (($_[0] <= $stop),  "Number must be no more than $stop.") }
                    :           sub { (($_[0] < $stop),   "Number must be less than $stop.") };

    if ($start eq '*' && $stop eq '*') {
        return sub { (1, '') };
    }
    elsif ($start eq '*') {
        return $check_stop;
    }
    elsif ($stop eq '*') {
        return $check_start;
    }
    else {
        return sub {
            my ($v, $e) = $check_start->(@_);
            return ($v, $e) unless $v;
            return $check_stop->(@_);
        }
    }
}

sub one_of {
    die "at least one value must be provided to one_of"
        unless @_ > 0;

    my @enum = @_;
    return sub {
        my ($value) = @_;
        for my $allowed (@enum) {
            return (1, '') if $value eq $allowed;
        }

        return (0, 'Must be one of: '
            . _comma_and( map { qq["$_"] } @enum )
        );
    };
}

sub split_by {
    my ($by, $count) = @_;

    die "missing string or regex to split by"
        unless defined $by;

    die "count must be greater than 1 if present"
        if defined $count && $count <= 1;

    if ($count) {
        sub { defined $_[0] ? [ split $by, $_[0], $count ] : [] }
    }
    else {
        sub { defined $_[0] ? [ split $by, $_[0] ] : [] }
    }
}

sub trim {
    my $only = shift // 'both';
    if ($only eq 'both') {
        return sub {
            return unless defined $_;
            s/\A\s+//;
            s/\s+\Z//r;
        };
    }
    elsif ($only eq 'left') {
        return sub {
            return unless defined $_;
            s/\A\s+//r;
        }
    }
    elsif ($only eq 'right') {
        return sub {
            return unless defined $_;
            s/\s+\Z//r;
        }
    }
    else {
        die qq[unknown trim option [$only], expected "both" or "left" or "right"];
    }
}

1;

=pod

=encoding UTF-8

=head1 NAME

FormValidator::Tiny - A tiny form validator

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use FormValidator::Tiny qw( :validation :predicates :filtesr );
    use Email::Valid;   # <-- for demonstration, not required
    use Email::Address; # <-- for demonstration, not required
    use Types::Standard qw( Int ); # <-- for demonstration, not required

    validation_spec edit_user => [
        login_name => [
            required => 1,
            must     => limit_character_set('_', 'a-z', 'A-Z', '0-9'),
            must     => length_in_range(5, 16),
        ],
        name => [
            required => 1,
            must     => length_in_range(1, 100),
        ],
        age => [
            optional => 1,
            into     => '+',
            must     => Int,
            must     => number_in_range(13, '*'),
        ],
        password => [
            required => 1,
            must     => length_in_range(8, 72),
        ],
        confirm_password => [
            required => 1,
            must     => equal_to('password'),
        ],
        email => [
            required => 1,
            must     => length_in_range(5, 250),
            must     => sub { (
                            !!Email::Valid->address($_),
                            "That is not a well-formed email address."
                        ) },
            into     => 'Email::Address',
        ],
        groups => [
            optional  => 1,
            into      => split_by(' '),
            into      => '[]',
            each_must => length_in_range(3, 20),
            each_must => limit_character_set(
                             ['_', 'a-z', 'A-Z'],
                             ['_', '-', 'a-z', 'A-Z', '0-9'],
                         ),
        ],
        tags   => [
            optional   => 1,
            into       => split_by(/\s*,\s*/),
            each_into  => split_by(/\s\*:\s*/, 2),
            into       => '{}',
            key_must   => length_in_range(3, 20),
            key_must   => qr/^(?:[A-Z][a-z0-9]*)(?:-[A-Z][a-z0-9]*)*)$/,
            with_error => 'Tags keys must be of a form like "Favorite" or "Welcome-Message".',
            value_must => length_in_range(1, 500),
            value_must => limit_character_set('_', '-', 'a-z', 'A-Z', '0-9'),
        ],
    ];

    # Somehow your web framework gets you a set of form parameters submitted by
    # POST or whatever. GO!
    my $params = web_framework_params_method();
    my ($parsed_params, $errors) = validate_form edit_user => $params;

    # You probably want better error handling
    if ($errors) {
        for my $field (keys %$errors) {
            print "Error in $field: $_\n" for @{ $errors->{$field} };
        }
    }

    # Form fields are valid, take action!
    else {
        do_the_thing(%$parased_params);
    }

=head1 DESCRIPTION

The API of this module is still under development and could change, but probably won't.

There are lots for form validators, but this one aims to be the one that just
does one thing and does it well without involving anything else if it can. If you
just need a small form validator without installing all of CPAN, this will do
that. If you want to install all of CPAN and use a readable form validation spec
syntax, I hope this will do that too.

This module requires Perl 5.18 or better as of this writing.

=head1 EXPORTS

This module exports three sets of functions, each with their own export tag:

=over

=item :validation

This is exported by default. It includes the two central functions provided by this interface, C<validation_spec> and C<validate_form>.

=item :predicates

This includes the built-in predicate helpers, used with C<must> and C<must>-like directives.

=over

=item limit_character_set

=item length_in_range

=item equal_to

=item number_in_range

=item one_of

=back

=item :filters

This includes the build-in filter helpers, used with C<into> and C<into>-like directives.

=over

=item split_by

=item trim

=back

=item :all

All of the above.

=back

=head1 FUNCTIONS

=head2 validation_spec

    validation_spec $spec_name => \@spec;

This defines a validation specification. It associates a specification named
C<$spec_name> with the current package. Any use of C<validate_form> within the
current package will use specifications named within the current package. The
following example would work fine as the "edit" spec defined in each controller
is in their respective package namespaces.

    package MyApp::Controller::User;
    validation_spec edit => [ ... ];
    sub process_edits {
        my ($self, $c) = @_;
        my ($p, $e) = validate_form edit => $c->req->body_parameters;
        ...
    }

    package MyApp::Controller::Page;
    validation_spec edit => [ ... ];
    sub process_edits {
        my ($self, $c) = @_;
        my ($p, $e) = validate_form edit => $c->req->body_parameters;
        ...
    }

If you want to define them into a different package, name the package as part of
the spec. Similarly, you can validate_form using a spec defined in a different
package by naming the package when calling L</validate_form>:

    package MyApp::Forms;
    validation_spec MyApp::Controller::User::edit => [ ... ];

    package MyApp::Controller::User;
    sub process_groups {
        my ($self, $c) = @_;
        my ($p, $e) = validate_form MyApp::Controller::UserGroup::edit => $c->req->body_parameters;
        ...
    }

You can also define your validation specification as lexical variables instead:

    my $spec = validation_spec [ ... ];
    my ($p, $e) = validate_form $spec, $c->req->body_parameters;

For information about how to craft a spec, see the L</VALIDATION SPECIFICATIONS>
section.

=head2 validate_form

    my ($params, $errors) = validate_form $spec, $input_parameters;

Compares the given parameters against the named spec. The C<$input_parameters>
may be provided as either a hash or an array of alternating key-value pairs. All
keys and values must be provided as strings.

The method returns two values. The first, C<$params>, is the parameters as far
as they have been validated so far. The second, C<$errors> is the errors that
have been detected.

The C<$params> will be provided as a hash. The keys of this hash will match the
keys given in the spec. Some keys may be missing if the provided
C<$input_parameters> did not contain values or those values are invalid.

If there are no errors, the C<$errors> value will be set to C<undef>. With
errors, this will be hash of arrays. The keys of the hash will also match the
keys in the spec. Only fields with a validation error will be set. Each value
is an array of strings, with each string being an error message describing a
validation failure.

=head2 limit_character_set

    must => limit_character_set(@sets)
    must => limit_character_set(\@fc_sets, \@rc_sets);

This returns a subroutine that limits the allowed characters for an input. In
the first form, the character set limits are applied to all characters in the
value. In the second, the first array limits the characters permitted for the
first character and the second limits the characters permitted for the rest.

Character sets may be provided as single letters (e.g., "_"), as named unicode
character properties wrapped in square brackets (e.g., "[Uppercase_Letter]"), or
as ranges connected by a hyphen (e.g., "a-z").

=head2 length_in_range

    must => length_in_range('*', 10)
    must => length_in_range(10, '*')
    must => length_in_range(10, 100)

This returns a subroutine for use with C<must> declarations that asserts the
minimum and maximum string character length permitted for a value. Use an
asterisk to define no limit.

=head2 equal_to

    must => equal_to('field')

This returns a subroutine for use with C<must> declarations that asserts that
the value must be exactly equal to another field in the input.

=head2 number_in_range

    must => number_in_range('*', 100)
    must => number_in_range(100, '*')
    must => number_in_range(100, 500)
    must => number_in_range(exclusive => 100, exclusive => 500)

Returns a predicate for must that requires the integer to be within the given
range. The endpoints are inclusive by default. You can add the word "exclusive"
before a value to make the comparison exclusive instead. Using a '*' indicates
no limit at that end of the range.

=head2 one_of

    must => one_of(qw( a b c )),

Returns a predicate that requires the value to exactly match one of the
enumerated values.

=head2 split_by

    into => split_by(' ')
    into => split_by(qr/,\s*/)
    into => split_by(' ', 2)
    into => split_by(qr/,\s*/, 10)

Returns an into filter that splits the string into an array. The arguments are
similar to those accepted by Perl's built-in C<split>.

=head2 trim

    into => trim
    into => trim('left')
    into => trim('right')

Returns an into filter that trims whitespace from the input value. You can
provide an argument to trim only the left whitespace or the right whitespace.

=head1 VALIDATION SPECIFICATIONS

The validation specification is an array reference. Each key names a field to
validate. The value is an array of processing declarations. Each processing
declaration is a key-value pair. The inputs will be processed in the order they
appear in the spec. The key names the type of processing. The value describes
arguments for the processing. The processing declarations will each be executed
in the order they appear. The same processor may be applied multiple times.

=head2 Input Declarations

Input declarations modify the initial value and must be given at the very top of
the list of declarations for a field before all others.

=head3 from

    from => 'input_parameter_name'

Without this declaration, the validator pulls input from the parameter with the
same name as the key named in the validation spec. This input declaration
changes the key used for input.

=head3 as

    multiple => 1

The multiple input declaration tells the validator whether to interpret the
input parameter as a multiple input or not. Without this declaration or with it
set to 0, the validator will interpret multiple inputs as a single value,
ignoring all but the last. With this declaration, it treat the input as multiple
items, even if there are 0 or 1.

=head3 trim

    trim => 0

The default behavior of L</validate_form> is to trim whitespace from the beginning
and end of a value before processing. You can use the C<trim> declaration to
disable that.

=head2 Filtering Declarations

Filtering declarations inserted into the validation spec will replace the input
value with the newly filtered value at the point at which the declaration is
encountered.

=head3 into

    into => '+'
    into => '?'
    into => '?+'
    into => '?perl'
    into => '?yes!no',
    into => '[]'
    into => '{}'
    into => 'Package::Name'
    into => sub { ... }
    into => TypeObject

This is a filter declaration that transforms the input using the named coercion.

=over

=item Numeric

Numeric coercion is performed using the '+' argument. This will convert the
value using Perl's built-in string-to-number conversion.

=item Boolean

Boolean coercion is performed using the '?' argument. This will convert the
value to boolean. It does not use Perl's normal mechanism, though. Instead, it
converts the string to boolean based on string length alone. If the string is
empty, it is false. If it is not empty it is true.

=item Boolean by Numeric

Boolean by Numeric coercion is performed using the '?+' argument. This will
first convert the string input to a number and then the number will be collapsed
to a boolean value such that 0 is false and any other value is true.

=item Boolean via Perl

Boolean via Perl coercion is performed using the '?perl' argument. This will
convert to boolean using Perl's usual boolean logic.

=item Boolean via Enumeration

Boolean via Enumeration coercion is performed using an argument that starts with
a question mark, '?', and contains an exclamation mark, '!'. The value between
the question mark and exclamation mark is the value that must be provided for a
true value. The value provided between the exclamation mark and the end of
string is the false value. Anything else will be treated as invalid and cause a
validation error.

=item Array

Using a value of '[]' will make sure the value is treated as an array. This is a
noop if the L</multiple> declaration is set or if a L</filter> returns an array.
If the value is still a single, though, this will make sure the input value is
placed inside an array references. This will also turn a hash value into an array.

=item Hash

Setting the declaration to '{}" will coerce the value to a hash. The even indexed
values in the array will become keys and the odd indexed values in the array
will become their respective values. If the value is not an array, it will turn
a single value into a key/value pair with the key and the pair both being equal
to the original value.

=item Package

A package coercion happens when the string given is a package name. This assumes
that passing the input value to the C<new> constructor of the named package will
do the right thing. If you need anything more complicated than that, you should
use a subroutine coercion.

=item Subroutine

A subroutine coercion converts the value using the given subroutine. The current
input value is passed as the single argument to the coercion (and also set as
the localized copy of C<$_>). The return value of the subroutine becomes the new
input value.

=item Type::Tiny Coercion

If an object is passed that provides a C<coerce> method. That method will be
called on the current input value and the result will be used as the new input
value.

=back

=head3 each_into

    each_into => '+'
    each_into => '?'
    each_into => '?+'
    each_into => '?perl'
    each_into => '?yes!no',
    each_into => '[]'
    each_into => '{}'
    each_into => 'Package::Name'
    each_into => sub { ... }
    each_into => TypeObject

Performs the same coercion as L</into>, but also works with arrays and hashes.
It will apply the filter to a single value or to all elements of an array or to
all keys and values of a hash.

=head3 key_into

    key_into => '+'
    key_into => '?'
    key_into => '?+'
    key_into => '?perl'
    key_into => '?yes!no',
    key_into => '[]'
    key_into => '{}'
    key_into => 'Package::Name'
    key_into => sub { ... }
    key_into => TypeObject

Performs the same coercion as L</into>, but also works with arrays and hashes.
It will apply the filter to a single value or to all even index elements of an
array or to all keys of a hash.

=head3 value_into

    value_into => '+'
    value_into => '?'
    value_into => '?+'
    value_into => '?perl'
    value_into => '?yes!no',
    value_into => '[]'
    value_into => '{}'
    value_into => 'Package::Name'
    value_into => sub { ... }
    value_into => TypeObject

Performs the same coercion as L</into>, but also works with arrays and hashes.
It will apply the filter to a single value or to all odd index elements of an
array or to all values of a hash.

=head2 Validation Declarations

=head3 required

=head3 optional

    required => 1
    required => 0
    optional => 1
    optional => 0

It is strongly recommended that all fields add this declaratoi immediately after
the input declarations, if any.

When required is set (or optional is set to 0), an initial validation check is
inserted that will fail if a value is not provided for this field. That value
must contain at least one character (after trimming, if trimming is not
disabled).

When optional is set (or required is set to 0), an initial validaiton check is
inserted that will shortcircuit the rest of the validation if no value is
provided.

=head3 must

    must => qr/.../
    must => sub { ... }
    must => TypeObject

This declaration states that the input given must match the described predicate.
The module supports three kinds of predicates:

=over

=item Regular Expression

This will match the given regular expression against the input. It is
recommended that the regular expression start with "^" or "\A" and end with "$"
or "\z" to force a total string match.

The error message for these validates is not very good, so you probably want to
combine use of this kind of predicate with a following L</with_error>
declaration.

=item Subroutine

    ($valid, $message) = $code->($value, \%fields);

The subroutine will be passed two values. The first is the input to test
(which will also be set in the localalized copy of C<$_>). This second value
passed is rest of the input as processing currently stands.

The return value must be a two elements list.

=over

=item 1.

The first value returned is a boolean indicating whether the validation has
passed. A true value (like 1) means validation passes and there's no error. A
false value (like 0) means validation does not pass and an error has occured.

There is a third option, which is to return C<undef>. This indicates that
validaton should stop here. This is neither a success nor a failure. The value
processed so far will be ignored, but no error message is returned either. Any
further declarations for the field will be ignored as well.

Returning C<undef> allows custom code to shortcircuit validation in exactly the
same was as setting C<optional>.

=item 2.

The second value is the error message to use. It is acceptable to return an
error message even if the first value is a true or undefined value.  In that
case, the error message will be ignored.

=back

=item Type::Tiny Object

The third option is to use a L<Type::Tiny>-style type object. The
L</validate_form> routine merely checks to see if it is an object that provides
a C<check> method or a C<validate_form> method. If it provides a C<check>
method, that method will be called and the boolean value returned will be
treated as the success or failure to validate. In this case, the error message
will be pulled from a call to C<get_message>, if such a method is provided. In
the C<validate_form> case, it will be called and a true value will be treated as
the error message and a false value as validation success.

It is my experience that the error messages provided by L<Type::Tiny> and
similar type systems are not friendly for use with end-uers. As such, it is
recommended that you provide a nicer error message with a following
L</with_error> declaration.

=back

=head3 each_must

    each_must => qr/.../
    each_must => sub { ... }
    each_must => TypeObject

This declaration establishes validation rules just like L</must>, but applies
the test to every value. If the input is an array, that will apply to every
value. If the input is a hash, it will apply to every key and every value of the
hash. If it is a single scalar, it will apply to that single value.

=head3 key_must

    key_must => qr/.../
    key_must => sub { ... }
    key_must => TypeObject

This is very similar to C<each_must>, but only applies to keys. It will apply to
a single value, or to the even index values of an array, or to the keys of a
hash.

=head3 value_must

    value_must => qr/.../
    value_must => sub { ... }
    value_must => TypeObject

This is very similar to C<each_must> and complement of C<key_must>. It will
apply to a single value, or to the odd index values of an array, or to the
values of a hash.

=head3 with_error

    with_error => 'Error message.'
    with_error => sub { ... }

This defines the error message to associate with the previous C<must>,
C<each_must>, C<key_must>, C<value_must>, C<into>, C<required>, and C<optional>
declaration. This will override any other associated message.

If you would like to provide a different message based on the input, you may
provide a subroutine.

=head1 SPECIAL VARIABLES

The validation specifications are defined in each packages where
L</validation_spec> is called. This is done through a package variable named
C<%FORM_VALIDATOR_TINY_SPECIFICATION>. If you really need to use that variable
for something else or if defining global package variables offends you, you can
use the return value form of C<validation_spec>, which will avoid creating this
variable.

If you stick to the regular interface, however, this variable will be
established the first time C<validation_spec> is called. The spec names are the
keys and the values have no documented definition. If you want to see what they
are, you must the read the code, but there's no guarantee that the internal
representation of this variable will stay the same in future releases.

=head1 SEE ALSO

L<Validate::Tiny> is very similar to this module in purpose and goals, but with
a different API.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


In any case, you may override the error message returned using a following
L</with_error> declaration.



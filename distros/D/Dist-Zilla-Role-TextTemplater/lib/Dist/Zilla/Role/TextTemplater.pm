#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Dist/Zilla/Role/TextTemplater.pm
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Dist-Zilla-Role-TextTemplater.
#
#   perl-Dist-Zilla-Role-TextTemplater is free software: you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Role-TextTemplater is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#   PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Role-TextTemplater. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

#pod =for :this This is C<Dist::Zilla::Role::TextTemplater> module documentation. Read this if you want to
#pod have text templating capabilities in your Dist::Zilla plugin.
#pod
#pod =for :those If you are using a C<TextTemplater>-based plugin, read the
#pod L<manual|Dist::Zilla::Role::TextTemplater::Manual>. General topics like getting source, building, installing, bug
#pod reporting and some others are covered in the F<README>.
#pod
#pod =for test_synopsis my ( $result, $template, $file );
#pod
#pod =head1 SYNOPSIS
#pod
#pod     package Dist::Zilla::Plugin::YourPlugin;
#pod     use Moose;
#pod     use namespace::autoclean;
#pod     with 'Dist::Zilla::Role::Plugin';
#pod     with 'Dist::Zilla::Role::TextTemplater';
#pod
#pod     sub method {
#pod         my $self = shift( @_ );
#pod         ...;
#pod         $result = $self->fill_in_string( $template );
#pod         ...;
#pod     };
#pod
#pod     sub another_method {
#pod         my $self = shift( @_ );
#pod         ...;
#pod         $self->fill_in_file( $file );
#pod         ...;
#pod     };
#pod
#pod     __PACKAGE__->meta->make_immutable;
#pod     1;
#pod
#pod =head1 DESCRIPTION
#pod
#pod The role provides a consuming plugin with C<fill_in_string> and C<fill_in_file> methods and bunch
#pod of accompanying attributes and F<dist.ini> options.
#pod
#pod =cut

package Dist::Zilla::Role::TextTemplater;

use Moose::Role;
use namespace::autoclean;
use version 0.77;

# ABSTRACT: Have text templating capabilities in your Dist::Zilla plugin
our $VERSION = 'v0.8.6'; # VERSION

with 'Dist::Zilla::Role::ErrorLogger' => { -version => 'v0.6.0' };  # Need `log_errors_in_file`.

use Carp qw{ croak };
use Dist::Zilla::File::InMemory;
use Dist::Zilla::File::OnDisk;
use List::Util qw{ min max };
use Text::Template qw{};

# --------------------------------------------------------------------------------------------------

#   It is a `my` variable, not a sub to keep consumer namespace clean.

my $tt_param = sub {
    my ( $name, $args ) = @_;
    return Text::Template::_param( $name, %$args );     ## no critic ( ProtectPrivateSubs )
};

# --------------------------------------------------------------------------------------------------

#pod =attr delimiters
#pod
#pod Pair of opening delimiter and closing delimiter to denote code fragments in template.
#pod
#pod Attribute introduces F<dist.ini> option with the same name. Option value will be split on
#pod whitespaces (result should be two items) to initialize the attribute.
#pod
#pod C<Str|ArrayRef[Str]>, read-only. Default value is C<[ '{{', '}}' ]>.
#pod
#pod See L<Dist::Zilla::Role::TextTemplater/"Delimiters">.
#pod
#pod =cut

has delimiters => (
    is          => 'ro',
    isa         => 'Str|ArrayRef[Str]',
    lazy        => 1,
    default     => sub { [ '{{', '}}' ] },
    trigger     => sub {
        my ( $self, $new ) = @_;
        if ( not ref( $new ) ) {
            $new =~ s{\A\s+}{}x;    # Drop leading ws, or `split` may leave the first item empty.
            $new = [ split( qr{\s+}x, $new ) ];
            @$new == 2
                or croak "\"delimiters\" value must be Str of *two* whitespace-separated words";
            $self->{ delimiters } = $new;
        } else {
            @$new == 2
                or croak "\"delimiters\" value must be ArrayRef with *two* elements";
        };
    },
);

# --------------------------------------------------------------------------------------------------

#pod =attr package
#pod
#pod Name of package to evaluate code fragments in.
#pod
#pod Attribute introduces F<dist.ini> option with the same name.
#pod
#pod C<Str>, read-only, optional.
#pod
#pod See L<Dist::Zilla::Role::TextTemplater/"Package">.
#pod
#pod =cut

has package => (
    is          => 'ro',
    isa         => 'Str',
    init_arg    => 'package',
);

# --------------------------------------------------------------------------------------------------

#pod =attr prepend
#pod
#pod Perl code to prepend to the beginning of every code fragment.
#pod
#pod Attribute introduces F<dist.ini> multi-value option with the same name.
#pod
#pod C<ArrayRef[Str]>, read-only, auto dereferenced. Default value is empty array. Consumers may specify
#pod alternative default by defining C<_build_prepend> method.
#pod
#pod See L<Dist::Zilla::Role::TextTemplater/"Prepend">.
#pod
#pod =cut

has prepend => (
    is          => 'ro',
    isa         => 'ArrayRef[Str]',
    builder     => '_build_prepend',
    auto_deref  => 1,
);

sub _build_prepend {
    return [];
};

# --------------------------------------------------------------------------------------------------

#pod =method tt_broken
#pod
#pod This method is called if a code fragment dies. It formats error message(s) and sends it to the log
#pod by calling C<log_error>.
#pod
#pod See C<BROKEN> option of L<Text::Template/"fill_in">.
#pod
#pod =cut

sub tt_broken {
    my ( $self, %args ) = @_;
    #
    #   Parse arguments.
    #
    my $tfile = $self->tt_file->name;   # Template filename.
    my $tline = $args{ lineno };        # Template line where the broken code fragment begins.
    my $tmesg = sprintf( 'Bad code fragment begins at %s line %d.', $tfile, $tline );
    my $emesg = $args{ error };         # Actual error message.
    my $eline = $emesg =~ m{ \s at \s \Q$tfile\E \s line \s (\d+)}x ? $1 : 0;
        # Line of actual error (if it is in template file, zero otherwise).
    chomp( $emesg );
    #
    # Report errors.
    #
    $self->log_error( $emesg );
    $self->log_error( '    ' . $tmesg );
        # ^ `croak` when reporting call stack, indents it with tab. Let's do the same. However,
        #   tab has unpredictable width, so let us indent 'call stack' by four spaces.
    #
    #   Now save errors to report in the template file.
    #
    if ( $eline ) {
        push( @{ $self->tt_errors }, $eline => $emesg );
    };
    if ( $tline != $eline ) {
        #   Do not report beginning of the bad code fragment if actual error occurred in the
        #   same file and line.
        push( @{ $self->tt_errors }, $tline => $tmesg );
    };
    return $emesg;
};

around tt_broken => sub {
    my ( $orig, $self, @args ) = @_;
    ++ $self->{ tt_broken_count };
    my $rc = $self->$orig( @args );
    if ( $self->tt_broken_count >= $self->tt_broken_limit ) {
        $self->log_error( [
            'Too many errors in %s, only first %d are reported.',
            $self->tt_file->name,
            $self->tt_broken_count,
        ] );
        $rc = undef;
    };
    return $rc;
};

# --------------------------------------------------------------------------------------------------

#pod =attr tt_file
#pod
#pod File being processed (either actual file or temporary C<InMemory> file when processing a string).
#pod Available only during template processing. May be used in C<tt_broken> method.
#pod
#pod C<Object>, read-only, not an init arg.
#pod
#pod =cut

has tt_file => (
    isa         => 'Object',
    is          => 'ro',
    init_arg    => undef,
);

# --------------------------------------------------------------------------------------------------

#pod =attr tt_errors
#pod
#pod Errors detected in template file, in format suitable for C<log_errors_in_file> (defined in
#pod C<ErrorLogger> role). May be used in C<tt_broken> method.
#pod
#pod C<ArrayRef>, read-write, not an init arg.
#pod
#pod =cut

has tt_errors => (
    isa         => 'ArrayRef',
    is          => 'rw',
    init_arg    => undef,
);

# --------------------------------------------------------------------------------------------------

#pod =attr tt_broken_count
#pod
#pod Number of C<tt_broken> calls. The counter is increased before C<tt_broken> call.
#pod
#pod C<Int>, read-only, not an init arg.
#pod
#pod =cut

has tt_broken_count => (
    is          => 'ro',
    isa         => 'Int',
    init_arg    => undef,
    default     => 0,
);

# --------------------------------------------------------------------------------------------------

#pod =attr tt_broken_limit
#pod
#pod If number of completed C<tt_broken> calls equals or exceeds this limit, processing stops.
#pod
#pod C<Int>, read-only, not an init arg, default value 10.
#pod
#pod There is no (official) way to change the attribute value now. Let me know if you need it.
#pod
#pod =cut

has tt_broken_limit => (
    is          => 'ro',
    isa         => 'Int',
    init_arg    => undef,
    default     => 10,
);


# --------------------------------------------------------------------------------------------------

#pod =method mvp_multivalue_args
#pod
#pod The method tells C<Dist::Zilla> that C<prepend> is a multi-value option.
#pod
#pod =cut

around mvp_multivalue_args => sub {
    my ( $orig, $self ) = @_;
    return ( $self->$orig(), qw{ prepend } );
};

# --------------------------------------------------------------------------------------------------

#pod =method tt_fill_in
#pod
#pod     $file = Dist::Zilla::File::OnDisk( ... );   # or
#pod     $file = Dist::Zilla::File::InMemory( ... ); # or
#pod     $file = Dist::Zilla::File::FromCode( ... );
#pod
#pod     $result = $self->fill_in_string( $file, \%variables, \%extra_args );
#pod     $result = $self->fill_in_string( $file );
#pod
#pod Internal working horse of the role.
#pod
#pod The method creates C<Text::Template> object, enforces C<Text::Template> to respect C<filename>
#pod argument (see L<FILENAME parameter has no
#pod effect|https://rt.cpan.org/Ticket/Display.html?id=106093>), takes care about warnings, then calls
#pod C<fill_in> method on the object, making C<Text::Template> compilation errors (if found) more
#pod user-friendly.
#pod
#pod C<< $file->content >> is passed to the C<Text::Template> constructor. C<\%variables>,
#pod C<\%extra_args>, and C<package>, C<prepend>, C<broken> attributes are combined and passed to both
#pod C<Text::Template> constructor and C<fill_in> method.
#pod
#pod C<\%variables> become C<hash> C<Text::Template> option (see L<Text::Template/"HASH"> for details).
#pod Variables C<plugin> (reference to object executing the method, i. e. C<$self>) and C<dist>
#pod (reference to C<Dist::Zilla>, i. e. C<< $self->zilla >>) are added to C<\%variables> automatically,
#pod if they are not exist.
#pod
#pod C<package>, C<prepend>, C<broken> attributes become same-name C<Text::Template> options.
#pod C<\%extra_args> is expanded to list and passed last, so caller can override any option specified by
#pod C<tt_fill_in> (except C<filename>), for example:
#pod
#pod     $self->tt_fill_in( $file, undef, { package => 'MY' } );
#pod
#pod will execute template code fragments in context of C<MY> package regardless of C<package>
#pod attribute. Another, a bit more complicated example:
#pod
#pod     $self->tt_fill_in( $file, undef, { hash => { } } );
#pod
#pod processes template with no predefined variables: C<plugin> and C<dist> are added to C<\%variables>,
#pod but entire C<\%variables> is overridden by C<hash> extra argument.
#pod
#pod C<tt_fill_in> takes special care about package: by default nested C<tt_fill_in> calls use the same
#pod package as the outermost call. Of course, if C<package> extra argument is explicitly specified in
#pod inner call, it takes priority over default package.
#pod
#pod When defining variables with either C<\%variables> argument or C<hash> extra argument, remember that
#pod C<Text::Template> dereferences all the references. It especially important if you want to pass
#pod a reference to template:
#pod
#pod     $array = [ … ]; $hash = { … };
#pod     $self->tt_fill_in(
#pod         $file,
#pod         { array => \$array, hash => \$hash, plugin => \$self },
#pod     );
#pod
#pod In template, C<$array> will be a reference to array, C<$hash> — reference to hash, C<$plugin> —
#pod reference to plugin. If you forget to take references, e. g.:
#pod
#pod     $self->tt_fill_in(
#pod         $file,
#pod         { array => $array, hash => $hash, plugin => $self },
#pod     );
#pod
#pod template will have C<@array> (array, not reference to array), C<%hash> (hash, not reference to
#pod hash), and C<$plugin> will be (oops!) undefined.
#pod
#pod Scalars can be passed either by reference or value:
#pod
#pod     $self->tt_fill_in(
#pod         $file,
#pod         { str1 => "string", str2 => \"string" },
#pod     );
#pod
#pod If C<$file> is mutable (i. e. does C<Dist::Zilla::Role::MutableFile> role), file content will be
#pod updated with result of template processing.
#pod
#pod See L<Text::Template/"HASH"> for more details.
#pod
#pod =cut

sub tt_fill_in {
    my ( $self, $file, $hash, $args ) = @_;
    $self->log_debug( [ 'processing %s', $file->name ] );
    my %hash = (
        plugin => \( $self ),
        dist   => \( $self->zilla ),
        $hash ? %$hash : (),
    );
    my %args = (
        hash       => \%hash,
        delimiters => $self->delimiters,
        ( package  => $self->package               ) x !! $self->package,
        ( prepend  => join( "\n", $self->prepend ) ) x !! $self->prepend,
        broken  => sub {
            my ( %args ) = @_;          ## no critic ( ProhibitReusedNames )
            return $args{ arg }->tt_broken( %args );
        },
        broken_arg => $self,
        $args ? %$args : (),
    );
    my ( $result, $errors ); {
        #   Original version of the code simply called `Text::Template::fill_in_string` function.
        #   However, this trivial approach does not work good because of `Text::Template` bug: it
        #   ignores `filename` argument, see <https://rt.cpan.org/Ticket/Display.html?id=106093>.
        #   It seems it will not be fixed soon. The bug can be workarounded by setting
        #   `Text::Template` object property `FILENAME`. In order to do it, we need access to
        #   `Text::Template` object, that means we have to create it manually, and then call
        #   `fill_in` method on it.
        local $Text::Template::ERROR = undef;
        my $tt = Text::Template->new( type => 'STRING', source => $file->content, %args );
        if ( defined( $tt ) and not defined( $Text::Template::ERROR ) ) {
            my $package = $tt_param->( 'package', \%args );
            if ( not defined( $package ) or $package eq '' ) {
                #   If package was not explicitly specified, create a private package.
                $package = Dist::Zilla::Role::TextTemplater::_Package->new();
            };
            #   Save package (either explicitly specified or auto-generated) in `package`
            #   attribute, to let recursive `fill_in_string` calls utilize the same package.
            local $self->{ package         } = "$package";
            local $self->{ tt_file         } = $file;   # Will be used in `broken`.
            local $self->{ tt_errors       } = [];
            local $self->{ tt_broken_count } = 0;
            $tt->{ FILENAME } = $file->name;            # Workaround for the bug.
            {
                local $SIG{ __WARN__ } = sub {  # TODO: Create an attribute?
                    my $msg = "$_[ 0 ]";        # Stringify message, it could be an object.
                    chomp( $msg );
                    $self->log( $msg );
                };
                $result = $tt->fill_in( %args, package => "$package" );
            }
            #   `Text::Template` doc says:
            #       If the `BROKEN` function returns undef, `Text::Template` will immediately abort
            #       processing the template and return the text that it has accumulated so far.
            #   It seems it is not true, `fill_in` returns `undef`, not text accumulated so far.
            if ( defined( $Text::Template::ERROR ) ) {
                #   There are only few error message which can be generated by "Text::Template":
                #       Unmatched close brace at line $lineno
                #       End of data inside program text that began at line $prog_start
                #       Couldn't open file $fn: $!
                #   The latter cannot occur because we always fill in strings, never files.
                #   The problem is that these error messages does not include template name. Let us
                #   try to make them more user-friendly.
                my $open  = qr{\QEnd of data inside program text that began\E}x;
                my $close = qr{\QUnmatched close brace\E}x;
                my $known = qr{\A (?: ($open) | $close ) \s at \s line \s (\d+) \z }x;
                if ( $Text::Template::ERROR =~ $known ) {
                    my ( $type, $line ) = ( $1, $2 );
                    my $msg = $type ? 'Unmatched opening delimiter' : 'Unmatched closing delimiter';
                        # ^ `Text::Template` error message "End of data inside program text that
                        #   began at…" is too long at too complicated. Let us replace it with
                        #   simpler one.
                    $Text::Template::ERROR =
                        sprintf( '%s at %s line %d.', $msg, $file->name, $line );
                    push( @{ $self->tt_errors }, $line => $Text::Template::ERROR );
                };
            };
            $errors = $self->tt_errors;
        };
        if ( defined( $Text::Template::ERROR ) ) {
            $self->log_error( $Text::Template::ERROR );
        };
    };
    if ( @$errors ) {
        $self->log_errors_in_file( $file, @$errors );
    };
    $self->abort_if_error();
    if ( $file->does( 'Dist::Zilla::Role::MutableFile' ) ) {
        $file->content( $result );
    };
    return $result;
};

# --------------------------------------------------------------------------------------------------

#pod =method fill_in_string
#pod
#pod     $template = '…';
#pod     $result = $self->fill_in_string( $template, \%variables, \%extra_args );
#pod     $result = $self->fill_in_string( $template );
#pod
#pod The primary method of the role.
#pod
#pod The C<fill_in_string> interface is compatible with the same-name method of C<TextTemplate> role, so
#pod this role can be used as a drop-in replacement for C<TextTemplate>. However, method is
#pod implemented slightly differently, it may cause subtle differences in behaviour.
#pod
#pod The method creates temporary C<Dist::Zilla::File::InMemory> object with name C<"template"> (it can
#pod be overridden by C<filename> extra argument, though) and calls C<tt_fill_in> method, passing down
#pod temporary file, C<\%variables> and C<\%extra_args>.
#pod
#pod =cut

sub fill_in_string {
    my ( $self, $string, $hash, $args ) = @_;
    return $self->tt_fill_in(
        Dist::Zilla::File::InMemory->new(
            name    => $tt_param->( 'filename', $args ) || 'template',
            content => $string,
        ),
        $hash,
        $args,
    );
};

# --------------------------------------------------------------------------------------------------

#pod =method fill_in_file
#pod
#pod     $file = Dist::Zilla::File::OnDisk->new( { … } );    # or
#pod     $file = Dist::Zilla::File::InMemory->new( { … } );  # or
#pod     $file = Dist::Zilla::File::FromCode->new( { … } );  # or
#pod     $file = Path::Tiny->new( 'filename' );              # or
#pod     $file = Path::Class::File->new( 'filename' );       # or
#pod     $file = 'filename.ext';
#pod
#pod     $result = $self->fill_in_file( $file, \%variables, \%extra_args );
#pod     $result = $self->fill_in_file( $file );
#pod
#pod Similar to C<fill_in_string>, but the first argument is not a template but a file object or file
#pod name to read template from. File can be any of C<Dist::Zilla> file types (file is read with
#pod C<content> method) or C<Path::Tiny> file (file is read with C<slurp_utf8> method), or
#pod C<Path::Class::File> (read by C<< slurp( iomode => '<:encoding(UTF-8)' ) >>) or just a file name
#pod (temporary C<Dist::Zilla::File::OnDisk> object is created internally).
#pod
#pod Note that C<filename> extra argument is ignored, file name cannot be overridden.
#pod
#pod The method returns result of template processing. If the file is mutable (i. e. does
#pod C<Dist::Zilla::Role::MutableFile>) file content is also updated.
#pod
#pod B<Note:> C<Dist::Zilla::Role::MutableFile> introduced in C<Dist::Zilla> version 5.000. In earlier
#pod versions there is no C<Dist::Zilla::Role::MutableFile> role and so, file content is never updated.
#pod
#pod =cut

sub fill_in_file {
    my ( $self, $file, $hash, $args ) = @_;
    my $class = blessed( $file );
    if ( $class ) {
        if ( $file->isa( 'Moose::Object' ) and $file->does( 'Dist::Zilla::Role::File' ) ) {
            # Do noting.
        } elsif ( $file->isa( 'Path::Tiny' ) ) {
            $file = Dist::Zilla::File::InMemory->new(
                name    => "$file",
                content => $file->slurp_utf8(),
            );
        } elsif ( $file->isa( 'Path::Class::File' ) ) {
            $file = Dist::Zilla::File::InMemory->new(
                name    => "$file",
                content => $file->slurp( iomode => '<:encoding(UTF-8)' ),
            );
        } else {
            croak "fill_in_file: unsupported file class: $class";
        };
    } else {
        $file = Dist::Zilla::File::OnDisk->new(
            name => "$file",
        );
    };
    return $self->tt_fill_in( $file, $hash, $args );
};

# --------------------------------------------------------------------------------------------------

#   Helper class to create private packages. Actual creation and deletion is implemented in
#   `Text::Template`, this class just adds automatical package deletion.

{
    ## no critic ( ProhibitMultiplePackages )
    package Dist::Zilla::Role::TextTemplater::_Package;

    use strict;
    use warnings;

    use overload '""' => sub {
        my ( $self ) = @_;
        return $self->{ name };
    };

    sub new {
        my ( $class ) = @_;
        my $self = {
            name => Text::Template::_gensym(),          ## no critic ( ProtectPrivateSubs )
        };
        return bless( $self, $class );
    };

    sub DESTROY {
        my ( $self ) = @_;
        Text::Template::_scrubpkg( $self->{ name } );   ## no critic ( ProtectPrivateSubs )
        return;
    };

}

# --------------------------------------------------------------------------------------------------

1;

# --------------------------------------------------------------------------------------------------

#pod =note C<Text::Template> option spelling
#pod
#pod C<Text::Template> allows a programmer to use different spelling of options: all-caps, first-caps,
#pod all-lowercase, with and without leading dash, e. g.: C<HASH>, C<Hash>, C<hash>, C<-HASH>, C<-Hash>,
#pod C<-hash>. This is documented feature.
#pod
#pod C<Text::Template> recommends to pick a style and stick with it. (BTW, C<Text::Template>
#pod documentation uses all-caps spelling.) This role picked all-lowercase style. This choice have
#pod subtle consequences. Let us consider an example:
#pod
#pod     $self->fill_in_string( $template, undef, { PACKAGE => 'MY' } );
#pod
#pod Extra option C<PACKAGE> may or may not have effect, depending on value of C<package> attribute (i.
#pod e. presence or absence C<package> option in F<dist.ini> file), because (this is not documented)
#pod spellings are not equal: different spellings have different priority. If C<PACKAGE> and C<package>
#pod are specified simultaneously, C<package> wins, C<PACKAGE> loses.
#pod
#pod This feature gives you a choice. If you want to ignore option specified by the user in F<dist.ini>
#pod and provide your value, use all-lowercase option name. If you want to provide default which can be
#pod overridden by the user, use all-caps options name.
#pod
#pod =cut

# --------------------------------------------------------------------------------------------------

#pod =note C<filename> option
#pod
#pod When C<Text::Template> reads template from a file, it uses the actual file name in error messages,
#pod e. g.:
#pod
#pod     Undefined subroutine &foo called at dir/filename.ext line n
#pod
#pod where I<dir/filename.ext> is the name of file containing the template. When C<Text::Template>
#pod processes a string, it uses word "template" instead of file name, e. g.:
#pod
#pod     Undefined subroutine &foo called at template line n
#pod
#pod The option C<filename> allows the caller to override it:
#pod
#pod     $self->fill_in_file( $file, undef, { filename => 'Assa.txt' } );
#pod
#pod Error message would look like:
#pod
#pod     Undefined subroutine &foo called at Assa.txt line n
#pod
#pod It may seem this does not make much sense, but in our case (C<Dist::Zilla> and its plugins)
#pod C<Text::Template> always processes strings and never reads files, because reading files is a duty
#pod of C<Dist::Zilla::File::OnDisk> class. Thus, using C<filename> option is critical to provide good
#pod error messages. Actually, C<fill_in_file> implementation looks like
#pod
#pod     $self->fill_in_string(
#pod         $file->content,
#pod         undef,
#pod         { filename => $file->name },
#pod     );
#pod
#pod There are two problems with the option, though:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod C<Text::Template> does not document this option.
#pod
#pod I believe it is a mistake and option should be documented.
#pod
#pod =item *
#pod
#pod C<Text::Template> ignores this option.
#pod
#pod I am sure this is a bug and hope it will be fixed eventually. I am afraid it will not be fixed
#pod soon, though.
#pod
#pod Meanwhile, C<TextTemplater> implements a workaround to let the option work, so C<TextTemplater>
#pod consumers can utilize the C<filename> option.
#pod
#pod =back
#pod
#pod =cut

# --------------------------------------------------------------------------------------------------

#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod = L<Dist::Zilla>
#pod = L<Dist::Zilla::Role>
#pod = L<Dist::Zilla::Plugin>
#pod = L<Dist::Zilla::Role::TextTemplate>
#pod = L<Text::Template>
#pod
#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2015, 2016 Van de Bugger
#pod
#pod License GPLv3+: The GNU General Public License version 3 or later
#pod <http://www.gnu.org/licenses/gpl-3.0.txt>.
#pod
#pod This is free software: you are free to change and redistribute it. There is
#pod NO WARRANTY, to the extent permitted by law.
#pod
#pod
#pod =cut

#   ------------------------------------------------------------------------------------------------
#
#   file: doc/what.pod
#
#   This file is part of perl-Dist-Zilla-Role-TextTemplater.
#
#   ------------------------------------------------------------------------------------------------

#pod =encoding UTF-8
#pod
#pod =head1 WHAT?
#pod
#pod C<Dist-Zilla-Role-TextTemplater> is a C<Dist::Zilla> role, a replacement for standard role C<TextTemplate>. Both
#pod roles have the same great C<Text::Template> engine under the hood, but this one provides better
#pod control over the engine and much better error reporting.
#pod
#pod =cut

# end of file #
#   ------------------------------------------------------------------------------------------------
#
#   file: doc/why.pod
#
#   This file is part of perl-Dist-Zilla-Role-TextTemplater.
#
#   ------------------------------------------------------------------------------------------------

#pod =encoding UTF-8
#pod
#pod =head1 WHY?
#pod
#pod C<TextTemplate> role from C<Dist::Zilla> distribution v5.037 has the same great C<Text::Template>
#pod engine under the hood, but lacks of control and has I<awful> error reporting.
#pod
#pod =head2 Error Reporting
#pod
#pod Let us consider an example. For sake of example simplicity, it contains only one file, F<dist.ini>.
#pod Two files, F<lib/Assa.pm> and F<lib/Assa.pod>, are generated on-the-fly with C<GenerateFile>
#pod plugin.
#pod
#pod Have a look at F<dist.ini>:
#pod
#pod     name     = Assa
#pod     version  = 0.001
#pod     abstract = Example
#pod     [GenerateFile/lib/Assa.pm]
#pod         filename = lib/Assa.pm
#pod         content  = package Assa; 1;
#pod     [GenerateFile/lib/Assa/Manual.pod]
#pod         filename = lib/Assa/Manual.pod
#pod         content  = =head1 NAME
#pod         content  =
#pod         content  = {{$dst->name} - {{$dist->abstract}}
#pod         content  =
#pod         content  = Version {{$dist->version}}.
#pod         content  =
#pod         content  = {{$dist->license->notice}}
#pod     [TemplateFiles]
#pod         filename = lib/Assa.pm
#pod         filename = lib/Assa/Manual.pod
#pod     [MetaResources::Template]
#pod         homepage = https://example.org/release/{{$dist->name}}
#pod         license  = {{$dist->license->url}}
#pod
#pod
#pod (Do you see a typo? How many? Note this is a small example, real files are much larger.) Now let us
#pod build the distribution:
#pod
#pod     $ dzil build
#pod     [DZ] beginning to build Assa
#pod     [TemplateFiles] Filling in the template returned undef for:
#pod     [TemplateFiles] =head1 NAME
#pod     [TemplateFiles]
#pod     [TemplateFiles] {{$dst->name} - {{$dist->abstract}}
#pod     [TemplateFiles]
#pod     [TemplateFiles] Version {{$dist->version}}.
#pod     [TemplateFiles]
#pod     [TemplateFiles] {{$dist->license->notice}}
#pod
#pod     [TemplateFiles] Filling in the template returned undef for:
#pod     [TemplateFiles] =head1 NAME
#pod     [TemplateFiles]
#pod     [TemplateFiles] {{$dst->name} - {{$dist->abstract}}
#pod     [TemplateFiles]
#pod     [TemplateFiles] Version {{$dist->version}}.
#pod     [TemplateFiles]
#pod     [TemplateFiles] {{$dist->license->notice}}
#pod      at /home/vdb/.usr/opt/local-lib/lib/perl5/x86_64-linux-thread-multi/Moose/Meta/Method/Delegation.pm line 110.
#pod
#pod
#pod Oops. What's happened? Where? Why? All we have is a highly unclear error message
#pod
#pod     Filling in the template returned undef for:
#pod
#pod and file content printed twice. (Yep, if the file had 1000 lines, we would have it printed twice
#pod too.) We do not ever have a file name and have to guess it by the content. Good bug hunting, dude.
#pod
#pod Ok, let us fix the problem (mistyped closing delimiter in the first line of file
#pod F<lib/Assa/Manual.pod>) and build the distribution again:
#pod
#pod     $ dzil build
#pod     [DZ] beginning to build Assa
#pod     Can't call method "name" on an undefined value at template line 3.
#pod
#pod
#pod Oops. Error message much is better now, but where the problem is? There are many templates in the
#pod project: F<lib/Assa.pm>, F<lib/Assa/Manual.pod>, and even resources in F<META.yml> — all are
#pod generated from templates. Where is the problem? Good bug hunting for us all.
#pod
#pod Such error reporting is simply unacceptable. I am a human, I often make mistakes, and I want the
#pod tool clearly warns me I<what> and I<where> the problem is, so I can fix it quickly. For example,
#pod in the first case I want to see:
#pod
#pod     $ dzil build
#pod     [DZ] beginning to build Assa
#pod     [Templates] Unmatched opening delimiter at lib/Assa/Manual.pod line 3.
#pod     [Templates] lib/Assa/Manual.pod:
#pod     [Templates]     1: =head1 NAME
#pod     [Templates]     2:
#pod     [Templates]     3: {{$dst->name} - {{$dist->abstract}}
#pod     [Templates]        ^^^ Unmatched opening delimiter at lib/Assa/Manual.pod line 3. ^^^
#pod     [Templates]     4:
#pod     [Templates]     5: Version {{$dist->version}}.
#pod     [Templates]        ... skipped 2 lines ...
#pod     Aborting...
#pod
#pod
#pod In the second case:
#pod
#pod     $ dzil build
#pod     [DZ] beginning to build Assa
#pod     [Templates] Can't call method "name" on an undefined value at lib/Assa/Manual.pod line 3.
#pod     [Templates] Bad code fragment begins at lib/Assa/Manual.pod line 3.
#pod     [Templates] lib/Assa/Manual.pod:
#pod     [Templates]     1: =head1 NAME
#pod     [Templates]     2:
#pod     [Templates]     3: {{$dst->name}} - {{$dist->abstract}}
#pod     [Templates]        ^^^ Can't call method "name" on an undefined value at lib/Assa/Manual.pod line 3. ^^^
#pod     [Templates]        ^^^ Bad code fragment begins at lib/Assa/Manual.pod line 3. ^^^
#pod     [Templates]     4:
#pod     [Templates]     5: Version {{$dist->version}}.
#pod     [Templates]        ... skipped 2 lines ...
#pod     Aborting...
#pod
#pod
#pod C<TextTemplater> makes it real. All I need is using C<TextTemplater>-based plugins: C<Templates>,
#pod C<MetaResources::Template> (starting from v0.002).
#pod
#pod =head2 Engine Control
#pod
#pod C<TextTemplater> allows the end-user to specify C<delimiters>, C<package> and C<prepend> engine
#pod options in F<dist.ini> file, while C<TextTemplate> allows to specify C<prepend> only
#pod programmatically, and does I<not> allow to specify C<delimiters> and C<package>.
#pod
#pod =cut

# end of file #


# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::TextTemplater - Have text templating capabilities in your Dist::Zilla plugin

=head1 VERSION

Version v0.8.6, released on 2016-11-18 20:03 UTC.

=head1 WHAT?

C<Dist-Zilla-Role-TextTemplater> is a C<Dist::Zilla> role, a replacement for standard role C<TextTemplate>. Both
roles have the same great C<Text::Template> engine under the hood, but this one provides better
control over the engine and much better error reporting.

This is C<Dist::Zilla::Role::TextTemplater> module documentation. Read this if you want to
have text templating capabilities in your Dist::Zilla plugin.

If you are using a C<TextTemplater>-based plugin, read the
L<manual|Dist::Zilla::Role::TextTemplater::Manual>. General topics like getting source, building, installing, bug
reporting and some others are covered in the F<README>.

=for test_synopsis my ( $result, $template, $file );

=head1 SYNOPSIS

    package Dist::Zilla::Plugin::YourPlugin;
    use Moose;
    use namespace::autoclean;
    with 'Dist::Zilla::Role::Plugin';
    with 'Dist::Zilla::Role::TextTemplater';

    sub method {
        my $self = shift( @_ );
        ...;
        $result = $self->fill_in_string( $template );
        ...;
    };

    sub another_method {
        my $self = shift( @_ );
        ...;
        $self->fill_in_file( $file );
        ...;
    };

    __PACKAGE__->meta->make_immutable;
    1;

=head1 DESCRIPTION

The role provides a consuming plugin with C<fill_in_string> and C<fill_in_file> methods and bunch
of accompanying attributes and F<dist.ini> options.

=head1 OBJECT ATTRIBUTES

=head2 delimiters

Pair of opening delimiter and closing delimiter to denote code fragments in template.

Attribute introduces F<dist.ini> option with the same name. Option value will be split on
whitespaces (result should be two items) to initialize the attribute.

C<Str|ArrayRef[Str]>, read-only. Default value is C<[ '{{', '}}' ]>.

See L<Dist::Zilla::Role::TextTemplater/"Delimiters">.

=head2 package

Name of package to evaluate code fragments in.

Attribute introduces F<dist.ini> option with the same name.

C<Str>, read-only, optional.

See L<Dist::Zilla::Role::TextTemplater/"Package">.

=head2 prepend

Perl code to prepend to the beginning of every code fragment.

Attribute introduces F<dist.ini> multi-value option with the same name.

C<ArrayRef[Str]>, read-only, auto dereferenced. Default value is empty array. Consumers may specify
alternative default by defining C<_build_prepend> method.

See L<Dist::Zilla::Role::TextTemplater/"Prepend">.

=head2 tt_file

File being processed (either actual file or temporary C<InMemory> file when processing a string).
Available only during template processing. May be used in C<tt_broken> method.

C<Object>, read-only, not an init arg.

=head2 tt_errors

Errors detected in template file, in format suitable for C<log_errors_in_file> (defined in
C<ErrorLogger> role). May be used in C<tt_broken> method.

C<ArrayRef>, read-write, not an init arg.

=head2 tt_broken_count

Number of C<tt_broken> calls. The counter is increased before C<tt_broken> call.

C<Int>, read-only, not an init arg.

=head2 tt_broken_limit

If number of completed C<tt_broken> calls equals or exceeds this limit, processing stops.

C<Int>, read-only, not an init arg, default value 10.

There is no (official) way to change the attribute value now. Let me know if you need it.

=head1 OBJECT METHODS

=head2 tt_broken

This method is called if a code fragment dies. It formats error message(s) and sends it to the log
by calling C<log_error>.

See C<BROKEN> option of L<Text::Template/"fill_in">.

=head2 mvp_multivalue_args

The method tells C<Dist::Zilla> that C<prepend> is a multi-value option.

=head2 tt_fill_in

    $file = Dist::Zilla::File::OnDisk( ... );   # or
    $file = Dist::Zilla::File::InMemory( ... ); # or
    $file = Dist::Zilla::File::FromCode( ... );

    $result = $self->fill_in_string( $file, \%variables, \%extra_args );
    $result = $self->fill_in_string( $file );

Internal working horse of the role.

The method creates C<Text::Template> object, enforces C<Text::Template> to respect C<filename>
argument (see L<FILENAME parameter has no
effect|https://rt.cpan.org/Ticket/Display.html?id=106093>), takes care about warnings, then calls
C<fill_in> method on the object, making C<Text::Template> compilation errors (if found) more
user-friendly.

C<< $file->content >> is passed to the C<Text::Template> constructor. C<\%variables>,
C<\%extra_args>, and C<package>, C<prepend>, C<broken> attributes are combined and passed to both
C<Text::Template> constructor and C<fill_in> method.

C<\%variables> become C<hash> C<Text::Template> option (see L<Text::Template/"HASH"> for details).
Variables C<plugin> (reference to object executing the method, i. e. C<$self>) and C<dist>
(reference to C<Dist::Zilla>, i. e. C<< $self->zilla >>) are added to C<\%variables> automatically,
if they are not exist.

C<package>, C<prepend>, C<broken> attributes become same-name C<Text::Template> options.
C<\%extra_args> is expanded to list and passed last, so caller can override any option specified by
C<tt_fill_in> (except C<filename>), for example:

    $self->tt_fill_in( $file, undef, { package => 'MY' } );

will execute template code fragments in context of C<MY> package regardless of C<package>
attribute. Another, a bit more complicated example:

    $self->tt_fill_in( $file, undef, { hash => { } } );

processes template with no predefined variables: C<plugin> and C<dist> are added to C<\%variables>,
but entire C<\%variables> is overridden by C<hash> extra argument.

C<tt_fill_in> takes special care about package: by default nested C<tt_fill_in> calls use the same
package as the outermost call. Of course, if C<package> extra argument is explicitly specified in
inner call, it takes priority over default package.

When defining variables with either C<\%variables> argument or C<hash> extra argument, remember that
C<Text::Template> dereferences all the references. It especially important if you want to pass
a reference to template:

    $array = [ … ]; $hash = { … };
    $self->tt_fill_in(
        $file,
        { array => \$array, hash => \$hash, plugin => \$self },
    );

In template, C<$array> will be a reference to array, C<$hash> — reference to hash, C<$plugin> —
reference to plugin. If you forget to take references, e. g.:

    $self->tt_fill_in(
        $file,
        { array => $array, hash => $hash, plugin => $self },
    );

template will have C<@array> (array, not reference to array), C<%hash> (hash, not reference to
hash), and C<$plugin> will be (oops!) undefined.

Scalars can be passed either by reference or value:

    $self->tt_fill_in(
        $file,
        { str1 => "string", str2 => \"string" },
    );

If C<$file> is mutable (i. e. does C<Dist::Zilla::Role::MutableFile> role), file content will be
updated with result of template processing.

See L<Text::Template/"HASH"> for more details.

=head2 fill_in_string

    $template = '…';
    $result = $self->fill_in_string( $template, \%variables, \%extra_args );
    $result = $self->fill_in_string( $template );

The primary method of the role.

The C<fill_in_string> interface is compatible with the same-name method of C<TextTemplate> role, so
this role can be used as a drop-in replacement for C<TextTemplate>. However, method is
implemented slightly differently, it may cause subtle differences in behaviour.

The method creates temporary C<Dist::Zilla::File::InMemory> object with name C<"template"> (it can
be overridden by C<filename> extra argument, though) and calls C<tt_fill_in> method, passing down
temporary file, C<\%variables> and C<\%extra_args>.

=head2 fill_in_file

    $file = Dist::Zilla::File::OnDisk->new( { … } );    # or
    $file = Dist::Zilla::File::InMemory->new( { … } );  # or
    $file = Dist::Zilla::File::FromCode->new( { … } );  # or
    $file = Path::Tiny->new( 'filename' );              # or
    $file = Path::Class::File->new( 'filename' );       # or
    $file = 'filename.ext';

    $result = $self->fill_in_file( $file, \%variables, \%extra_args );
    $result = $self->fill_in_file( $file );

Similar to C<fill_in_string>, but the first argument is not a template but a file object or file
name to read template from. File can be any of C<Dist::Zilla> file types (file is read with
C<content> method) or C<Path::Tiny> file (file is read with C<slurp_utf8> method), or
C<Path::Class::File> (read by C<< slurp( iomode => '<:encoding(UTF-8)' ) >>) or just a file name
(temporary C<Dist::Zilla::File::OnDisk> object is created internally).

Note that C<filename> extra argument is ignored, file name cannot be overridden.

The method returns result of template processing. If the file is mutable (i. e. does
C<Dist::Zilla::Role::MutableFile>) file content is also updated.

B<Note:> C<Dist::Zilla::Role::MutableFile> introduced in C<Dist::Zilla> version 5.000. In earlier
versions there is no C<Dist::Zilla::Role::MutableFile> role and so, file content is never updated.

=head1 NOTES

=head2 C<Text::Template> option spelling

C<Text::Template> allows a programmer to use different spelling of options: all-caps, first-caps,
all-lowercase, with and without leading dash, e. g.: C<HASH>, C<Hash>, C<hash>, C<-HASH>, C<-Hash>,
C<-hash>. This is documented feature.

C<Text::Template> recommends to pick a style and stick with it. (BTW, C<Text::Template>
documentation uses all-caps spelling.) This role picked all-lowercase style. This choice have
subtle consequences. Let us consider an example:

    $self->fill_in_string( $template, undef, { PACKAGE => 'MY' } );

Extra option C<PACKAGE> may or may not have effect, depending on value of C<package> attribute (i.
e. presence or absence C<package> option in F<dist.ini> file), because (this is not documented)
spellings are not equal: different spellings have different priority. If C<PACKAGE> and C<package>
are specified simultaneously, C<package> wins, C<PACKAGE> loses.

This feature gives you a choice. If you want to ignore option specified by the user in F<dist.ini>
and provide your value, use all-lowercase option name. If you want to provide default which can be
overridden by the user, use all-caps options name.

=head2 C<filename> option

When C<Text::Template> reads template from a file, it uses the actual file name in error messages,
e. g.:

    Undefined subroutine &foo called at dir/filename.ext line n

where I<dir/filename.ext> is the name of file containing the template. When C<Text::Template>
processes a string, it uses word "template" instead of file name, e. g.:

    Undefined subroutine &foo called at template line n

The option C<filename> allows the caller to override it:

    $self->fill_in_file( $file, undef, { filename => 'Assa.txt' } );

Error message would look like:

    Undefined subroutine &foo called at Assa.txt line n

It may seem this does not make much sense, but in our case (C<Dist::Zilla> and its plugins)
C<Text::Template> always processes strings and never reads files, because reading files is a duty
of C<Dist::Zilla::File::OnDisk> class. Thus, using C<filename> option is critical to provide good
error messages. Actually, C<fill_in_file> implementation looks like

    $self->fill_in_string(
        $file->content,
        undef,
        { filename => $file->name },
    );

There are two problems with the option, though:

=over

=item *

C<Text::Template> does not document this option.

I believe it is a mistake and option should be documented.

=item *

C<Text::Template> ignores this option.

I am sure this is a bug and hope it will be fixed eventually. I am afraid it will not be fixed
soon, though.

Meanwhile, C<TextTemplater> implements a workaround to let the option work, so C<TextTemplater>
consumers can utilize the C<filename> option.

=back

=head1 WHY?

C<TextTemplate> role from C<Dist::Zilla> distribution v5.037 has the same great C<Text::Template>
engine under the hood, but lacks of control and has I<awful> error reporting.

=head2 Error Reporting

Let us consider an example. For sake of example simplicity, it contains only one file, F<dist.ini>.
Two files, F<lib/Assa.pm> and F<lib/Assa.pod>, are generated on-the-fly with C<GenerateFile>
plugin.

Have a look at F<dist.ini>:

    name     = Assa
    version  = 0.001
    abstract = Example
    [GenerateFile/lib/Assa.pm]
        filename = lib/Assa.pm
        content  = package Assa; 1;
    [GenerateFile/lib/Assa/Manual.pod]
        filename = lib/Assa/Manual.pod
        content  = =head1 NAME
        content  =
        content  = {{$dst->name} - {{$dist->abstract}}
        content  =
        content  = Version {{$dist->version}}.
        content  =
        content  = {{$dist->license->notice}}
    [TemplateFiles]
        filename = lib/Assa.pm
        filename = lib/Assa/Manual.pod
    [MetaResources::Template]
        homepage = https://example.org/release/{{$dist->name}}
        license  = {{$dist->license->url}}

(Do you see a typo? How many? Note this is a small example, real files are much larger.) Now let us
build the distribution:

    $ dzil build
    [DZ] beginning to build Assa
    [TemplateFiles] Filling in the template returned undef for:
    [TemplateFiles] =head1 NAME
    [TemplateFiles]
    [TemplateFiles] {{$dst->name} - {{$dist->abstract}}
    [TemplateFiles]
    [TemplateFiles] Version {{$dist->version}}.
    [TemplateFiles]
    [TemplateFiles] {{$dist->license->notice}}

    [TemplateFiles] Filling in the template returned undef for:
    [TemplateFiles] =head1 NAME
    [TemplateFiles]
    [TemplateFiles] {{$dst->name} - {{$dist->abstract}}
    [TemplateFiles]
    [TemplateFiles] Version {{$dist->version}}.
    [TemplateFiles]
    [TemplateFiles] {{$dist->license->notice}}
     at /home/vdb/.usr/opt/local-lib/lib/perl5/x86_64-linux-thread-multi/Moose/Meta/Method/Delegation.pm line 110.

Oops. What's happened? Where? Why? All we have is a highly unclear error message

    Filling in the template returned undef for:

and file content printed twice. (Yep, if the file had 1000 lines, we would have it printed twice
too.) We do not ever have a file name and have to guess it by the content. Good bug hunting, dude.

Ok, let us fix the problem (mistyped closing delimiter in the first line of file
F<lib/Assa/Manual.pod>) and build the distribution again:

    $ dzil build
    [DZ] beginning to build Assa
    Can't call method "name" on an undefined value at template line 3.

Oops. Error message much is better now, but where the problem is? There are many templates in the
project: F<lib/Assa.pm>, F<lib/Assa/Manual.pod>, and even resources in F<META.yml> — all are
generated from templates. Where is the problem? Good bug hunting for us all.

Such error reporting is simply unacceptable. I am a human, I often make mistakes, and I want the
tool clearly warns me I<what> and I<where> the problem is, so I can fix it quickly. For example,
in the first case I want to see:

    $ dzil build
    [DZ] beginning to build Assa
    [Templates] Unmatched opening delimiter at lib/Assa/Manual.pod line 3.
    [Templates] lib/Assa/Manual.pod:
    [Templates]     1: =head1 NAME
    [Templates]     2:
    [Templates]     3: {{$dst->name} - {{$dist->abstract}}
    [Templates]        ^^^ Unmatched opening delimiter at lib/Assa/Manual.pod line 3. ^^^
    [Templates]     4:
    [Templates]     5: Version {{$dist->version}}.
    [Templates]        ... skipped 2 lines ...
    Aborting...

In the second case:

    $ dzil build
    [DZ] beginning to build Assa
    [Templates] Can't call method "name" on an undefined value at lib/Assa/Manual.pod line 3.
    [Templates] Bad code fragment begins at lib/Assa/Manual.pod line 3.
    [Templates] lib/Assa/Manual.pod:
    [Templates]     1: =head1 NAME
    [Templates]     2:
    [Templates]     3: {{$dst->name}} - {{$dist->abstract}}
    [Templates]        ^^^ Can't call method "name" on an undefined value at lib/Assa/Manual.pod line 3. ^^^
    [Templates]        ^^^ Bad code fragment begins at lib/Assa/Manual.pod line 3. ^^^
    [Templates]     4:
    [Templates]     5: Version {{$dist->version}}.
    [Templates]        ... skipped 2 lines ...
    Aborting...

C<TextTemplater> makes it real. All I need is using C<TextTemplater>-based plugins: C<Templates>,
C<MetaResources::Template> (starting from v0.002).

=head2 Engine Control

C<TextTemplater> allows the end-user to specify C<delimiters>, C<package> and C<prepend> engine
options in F<dist.ini> file, while C<TextTemplate> allows to specify C<prepend> only
programmatically, and does I<not> allow to specify C<delimiters> and C<package>.

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla>

=item L<Dist::Zilla::Role>

=item L<Dist::Zilla::Plugin>

=item L<Dist::Zilla::Role::TextTemplate>

=item L<Text::Template>

=back

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, 2016 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut

#line 1 "inc/Module/Install.pm - /kunden/homepages/6/d100394168/htdocs/.perlprefix/lib//Module/Install.pm"
# $File: //depot/cpan/Module-Install/lib/Module/Install.pm $ $Author: autrijus $
# $Revision: #69 $ $Change: 2301 $ $DateTime: 2004/07/13 07:16:40 $ vim: expandtab shiftwidth=4

package Module::Install;
$VERSION = '0.35';

die << "." unless $INC{join('/', inc => split(/::/, __PACKAGE__)).'.pm'};
Please invoke ${\__PACKAGE__} with:

    use inc::${\__PACKAGE__};

not:

    use ${\__PACKAGE__};

.

use strict 'vars';
use Cwd ();
use File::Find ();
use File::Path ();

@inc::Module::Install::ISA = 'Module::Install';
*inc::Module::Install::VERSION = *VERSION;

#line 132

sub import {
    my $class = shift;
    my $self = $class->new(@_);

    if (not -f $self->{file}) {
        require "$self->{path}/$self->{dispatch}.pm";
        File::Path::mkpath("$self->{prefix}/$self->{author}");
        $self->{admin} =
          "$self->{name}::$self->{dispatch}"->new(_top => $self);
        $self->{admin}->init;
        @_ = ($class, _self => $self);
        goto &{"$self->{name}::import"};
    }

    *{caller(0) . "::AUTOLOAD"} = $self->autoload;

    # Unregister loader and worker packages so subdirs can use them again
    delete $INC{"$self->{file}"};
    delete $INC{"$self->{path}.pm"};
}

=item autoload()

Returns an AUTOLOAD handler bound to the caller package.

=cut

sub autoload {
    my $self = shift;
    my $caller = caller;

    my $cwd = Cwd::cwd();
    my $sym = "$caller\::AUTOLOAD";

    $sym->{$cwd} = sub {
        my $pwd = Cwd::cwd();
        if (my $code = $sym->{$pwd}) {
            goto &$code unless $cwd eq $pwd; # delegate back to parent dirs
        }
        $$sym =~ /([^:]+)$/ or die "Cannot autoload $caller";
        unshift @_, ($self, $1);
        goto &{$self->can('call')} unless uc($1) eq $1;
    };
}

=item new(%args)

Constructor, taking a hash of named arguments.  Usually you do not want
change any of them.

=cut

sub new {
    my ($class, %args) = @_;

    return $args{_self} if $args{_self};

    $args{dispatch} ||= 'Admin';
    $args{prefix}   ||= 'inc';
    $args{author}   ||= '.author';
    $args{bundle}   ||= 'inc/BUNDLES';

    $class =~ s/^\Q$args{prefix}\E:://;
    $args{name}     ||= $class;
    $args{version}  ||= $class->VERSION;

    unless ($args{path}) {
        $args{path}  = $args{name};
        $args{path}  =~ s!::!/!g;
    }
    $args{file}     ||= "$args{prefix}/$args{path}.pm";

    bless(\%args, $class);
}

=item call($method, @args)

Call an extension method, passing C<@args> to it.

=cut

sub call {
    my $self   = shift;
    my $method = shift;
    my $obj = $self->load($method) or return;

    unshift @_, $obj;
    goto &{$obj->can($method)};
}

=item load($method)

Include and load an extension object implementing C<$method>.

=cut

sub load {
    my ($self, $method) = @_;

    $self->load_extensions(
        "$self->{prefix}/$self->{path}", $self
    ) unless $self->{extensions};

    foreach my $obj (@{$self->{extensions}}) {
        return $obj if $obj->can($method);
    }

    my $admin = $self->{admin} or die << "END";
The '$method' method does not exist in the '$self->{prefix}' path!
Please remove the '$self->{prefix}' directory and run $0 again to load it.
END

    my $obj = $admin->load($method, 1);
    push @{$self->{extensions}}, $obj;

    $obj;
}

=item load_extensions($path, $top_obj)

Loads all extensions under C<$path>; for each extension, create a
singleton object with C<_top> pointing to C<$top_obj>, and populates the
arrayref C<$self-E<gt>{extensions}> with those objects.

=cut

sub load_extensions {
    my ($self, $path, $top_obj) = @_;

    unshift @INC, $self->{prefix}
        unless grep { $_ eq $self->{prefix} } @INC;

    local @INC = ($path, @INC);
    foreach my $rv ($self->find_extensions($path)) {
        my ($file, $pkg) = @{$rv};
        next if $self->{pathnames}{$pkg};

        eval { require $file; 1 } or (warn($@), next);
        $self->{pathnames}{$pkg} = delete $INC{$file};
        push @{$self->{extensions}}, $pkg->new( _top => $top_obj );
    }
}

=item load_extensions($path)

Returns an array of C<[ $file_name, $package_name ]> for each extension
module found under C<$path> and its subdirectories.

=cut

sub find_extensions {
    my ($self, $path) = @_;
    my @found;

    File::Find::find(sub {
        my $file = $File::Find::name;
        return unless $file =~ m!^\Q$path\E/(.+)\.pm\Z!is;
        return if $1 eq $self->{dispatch};

        $file = "$self->{path}/$1.pm";
        my $pkg = "$self->{name}::$1"; $pkg =~ s!/!::!g;
        push @found, [$file, $pkg];
    }, $path) if -d $path;

    @found;
}

1;

__END__

=back

=head1 EXTENSIONS

All extensions belong to the B<Module::Install::*> namespace, and
inherit from B<Module::Install::Base>.  There are three categories
of extensions:

=over 4

=item Standard Extensions

Methods defined by a standard extension may be called as plain functions
inside F<Makefile.PL>; a corresponding singleton object will be spawned
automatically.  Other extensions may also invoke its methods just like
their own methods:

    # delegates to $other_extension_obj->method_name(@args)
    $self->method_name(@args);

At the first time an extension's method is invoked, a POD-stripped
version of it will be included under the F<inc/Module/Install/>
directory, and becomes I<fixed> -- i.e. even if the user had installed a
different version of the same extension, the included one will still be
used instead.

If the author wish to upgrade extensions in F<inc/> with installed ones,
simply run C<perl Makefile.PL> again; B<Module::Install> determines
whether you are an author by the existence of the F<inc/.author/>
directory.  End-users can reinitialize everything and become the author
by typing C<make realclean> and C<perl Makefile.PL>.

=item Private Extensions

Those extensions take the form of B<Module::Install::PRIVATE> and
B<Module::Install::PRIVATE::*>.

Authors are encouraged to put all existing F<Makefile.PL> magics into
such extensions (e.g. F<Module::Install::PRIVATE> for common bits;
F<Module::Install::PRIVATE::DISTNAME> for functions specific to a
distribution).

Private extensions should not to be released on CPAN; simply put them
somewhere in your C<@INC>, under the C<Module/Install/> directory, and
start using their functions in F<Makefile.PL>.  Like standard
extensions, they will never be installed on the end-user's machine,
and therefore never conflict with other people's private extensions.

=item Administrative Extensions

Extensions under the B<Module::Install::Admin::*> namespace are never
included with the distribution.  Their methods are not directly
accessible from F<Makefile.PL> or other extensions; they are invoked
like this:

    # delegates to $other_admin_extension_obj->method_name(@args)
    $self->admin->method_name(@args);

These methods only take effect during the I<initialization> run, when
F<inc/> is being populated; they are ignored for end-users.  Again,
to re-initialize everything, just run C<perl Makefile.PL> as the author.

Scripts (usually one-liners in F<Makefile>) that wish to dispatch
B<AUTOLOAD> functions into administrative extensions (instead of
standard extensions) should use the B<Module::Install::Admin> module
directly.  See L<Module::Install::Admin> for details.

=back

B<Module::Install> comes with several standard extensions:

=over 4

=item Module::Install::AutoInstall

Provides C<auto_install()> to automatically fetch and install
prerequisites via B<CPANPLUS> or B<CPAN>, specified either by
the C<features> metadata or by method arguments.

You may wish to add a C<include('ExtUtils::AutoInstall');> before
C<auto_install()> to include B<ExtUtils::AutoInstall> with your
distribution.  Otherwise, this extension will attempt to automatically
install it from CPAN.

=item Module::Install::Base

The base class of all extensions, providing C<new>, C<initialized>,
C<admin>, C<load> and the C<AUTOLOAD> dispatcher.

=item Module::Install::Build

Provides C<&Build-E<gt>write> to generate a B<Module::Build> compliant
F<Build> file, as well as other B<Module::Build> support functions.

=item Module::Install::Bundle

Provides C<bundle>, C<bundle_deps> and C<bundle_all>, allowing you
to bundle a CPAN distribution within your distribution.  When your
end-users install your distribution, the bundled distribution will be
installed along with yours, unless a newer version of the bundled
distribution already exists on their local filesystem.

=item Module::Install::Fetch

Handles fetching files from remote servers via FTP.

=item Module::Install::Include

Provides the C<include($pkg)> function to include pod-stripped
package(s) from C<@INC> to F<inc/>, and the C<auto_include()>
function to include all modules specified in C<build_requires>,

Also provides the C<include_deps($pkg)> function to include every
non-core modules needed by C<$pkg>, and the C<auto_include_deps()>
function that does the same thing as C<auto_include()>, plus all
recursive dependencies that are subsequently required by modules in
C<build_requires>.

=item Module::Install::Inline

Provides C<&Inline-E<gt>write> to replace B<Inline::MakeMaker>'s
functionality of making (and cleaning after) B<Inline>-based modules.

However, you should invoke this with C<WriteAll( inline => 1 )> instead.

=item Module::Install::MakeMaker

Simple wrapper class for C<ExtUtils::MakeMaker::WriteMakefile>.

=item Module::Install::Makefile

Provides C<&Makefile-E<gt>write> to generate a B<ExtUtils::MakeMaker>
compliant F<Makefile>; preferred over B<Module::Install::MakeMaker>.
It adds several extra C<make> targets, as well as being more intelligent
at guessing unspecified arguments.

=item Module::Install::Makefile::Name

Guess the distribution name.

=item Module::Install::Makefile::Version

Guess the distribution version.

=item Module::Install::Metadata

Provides C<&Meta-E<gt>write> to generate a B<YAML>-compliant F<META.yml>
file, and C<&Meta-E<gt>read> to parse it for C<&Makefile>, C<&Build> and
C<&AutoInstall> to use.

=item Module::Install::PAR

Makes pre-compiled module binary packages from F<blib>, and download
existing ones to save the user from recompiling.

=item Module::Install::Run

Determines if a command is available on the user's machine, and run
external commands via B<IPC::Run3>.

=item Module::Install::Scripts

Handles packaging and installation of scripts, instead of modules.

=item Module::Install::Win32

Functions related for installing modules on Win32, e.g. automatically
fetching and installing F<nmake.exe> for users that need it.

=item Module::Install::WriteAll

This extension offers C<WriteAll>, which writes F<META.yml> and
either F<Makefile> or F<Build> depending on how the program was
invoked.

C<WriteAll> takes four optional named parameters:

=over 4

=item C<check_nmake> (defaults to true)

If true, invokes functions with the same name.

=item C<inline> (defaults to false)

If true, invokes C<&Inline-E<gt>write> instead of C<&Makefile-E<gt>write>.

=item C<meta> (defaults to true)

If true, writes a C<META.yml> file.

=item C<sign> (defaults to false)

If true, invokes functions with the same name.

=back

=back

B<Module::Install> also comes with several administrative extensions:

=over

=item Module::Install::Admin::Find

Functions for finding extensions, installed packages and files in
subdirectories.

=item Module::Install::Admin::Manifest

Functions for manipulating and updating the F<MANIFEST> file.

=item Module::Install::Admin::Metadata

Functions for manipulating and updating the F<META.yml> file.

=item Module::Install::Admin::ScanDeps

Handles scanning for non-core dependencies via B<Module::ScanDeps> and
B<Module::CoreList>.

=back

Please consult their own POD documentations for detailed information.

=head1 FAQ

=head2 What are the benefits of using B<Module::Install>?

Here is a brief overview of the reasons:

    Does everything ExtUtils::MakeMaker does.
    Requires no installation for end-users.
    Generate stock Makefile.PL for Module::Build users.
    Guaranteed forward-compatibility.
    Automatically updates your MANIFEST.
    Distributing scripts is easy.
    Include prerequisite modules (even the entire dependency tree).
    Auto-installation of prerequisites.
    Support for Inline-based modules.
    Support for precompiled PAR binaries.

Besides, if you maintain more than one CPAN modules, chances are there
are duplications in their F<Makefile.PL>, and also with other CPAN module
you copied the code from.  B<Module::Install> makes it really easy for you
to abstract away such codes; see the next question.

=head2 How is this different from its predecessor, B<CPAN::MakeMaker>?

According to Brian Ingerson, the author of B<CPAN::MakeMaker>,
their difference is that I<Module::Install is sane>.

Also, this module is not self-modifying, and offers a clear separation
between standard, private and administrative extensions.  Therefore
writing extensions for B<Module::Install> is easier -- instead of
tweaking your local copy of C<CPAN/MakeMaker.pm>, just make your own
B<Modula::Install::PRIVATE> module, or a new B<Module::Install::*>
extension.

=head1 SEE ALSO

L<Module::Install-Cookbook>,
L<Module::Install-Philosophy>,
L<inc::Module::Install>

L<Module::Install::AutoInstall>,
L<Module::Install::Base>,
L<Module::Install::Bundle>,
L<Module::Install::Build>,
L<Module::Install::Directives>,
L<Module::Install::Fetch>,
L<Module::Install::Include>,
L<Module::Install::MakeMaker>,
L<Module::Install::Makefile>,
L<Module::Install::Makefile::CleanFiles>,
L<Module::Install::Makefile::Name>,
L<Module::Install::Makefile::Version>,
L<Module::Install::Metadata>,
L<Module::Install::PAR>,
L<Module::Install::Run>,
L<Module::Install::Scripts>,
L<Module::Install::Win32>
L<Module::Install::WriteAll>

L<Module::Install::Admin>,
L<Module::Install::Admin::Bundle>,
L<Module::Install::Admin::Find>,
L<Module::Install::Admin::Include>,
L<Module::Install::Admin::Makefile>,
L<Module::Install::Admin::Manifest>,
L<Module::Install::Admin::Metadata>,
L<Module::Install::Admin::ScanDeps>
L<Module::Install::Admin::WriteAll>

L<CPAN::MakeMaker>,
L<Inline::MakeMaker>,
L<ExtUtils::MakeMaker>,
L<Module::Build>

=head1 AUTHORS

Brian Ingerson E<lt>INGY@cpan.orgE<gt>,
Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2002, 2003, 2004 by
Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>,
Brian Ingerson E<lt>INGY@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

package Dist::Conformance::Check::SystemPackages 0.004;

# ABSTRACT: The system packages that a repository declares in metamerge.yml, validated, and resolved for a host

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base 'Dist::Conformance::Check', -signatures;

use Lingua::EN::Inflect();
use List::Util();

use Dist::Conformance::Schema();
use Dist::Conformance::Snapshot::Directory();


our $FILE        = 'metamerge.yml';
our $PACKAGES    = 'x_system_packages';
our $SOURCES     = 'x_system_sources';
our $DEPENDENCY  = '\A[A-Za-z0-9][A-Za-z0-9_.+:-]*\z';
our $SOURCE_NAME = '\A[a-z0-9][a-z0-9.-]*\z';

# The name of a packager, as Provisioner::Packager->named takes it.  test is not one.
our $PACKAGER = '\A(?!test\z)[a-z][a-z0-9]*\z';

our %PACKAGE_NAME = ( deb => '\A[a-z0-9][a-z0-9+.-]*[a-z0-9+.]\z' );

our $ANY_PACKAGE_NAME = '\A[A-Za-z0-9](?:[A-Za-z0-9+._-]*[A-Za-z0-9+._])?\z';

# DISTRO or DISTRO/RELEASE, in the characters that os-release allows in ID and VERSION_ID.
our $HOST = '\A[a-z0-9._-]+(?:/[a-z0-9._-]+)?\z';

my sub list_of ($item) { return { type => 'array', minItems => 1, items => $item } }

# The keywords of a mapping that must have a key other than $key, which refuse it with $message.
my sub more_than ( $key, $message ) {
    return (
        minProperties    => 1,
        not              => { required      => [$key],   maxProperties => 1 },
        'x-errorMessage' => { minProperties => $message, not           => $message },
    );
}

my sub entry_of ($pattern) {
    my $name = { type => 'string', pattern => $pattern };
    return {
        anyOf => [
            $name,
            {
                type => 'object',
                more_than( source => 'names no package, as name or for a distro' ),
                additionalProperties => 0,
                properties           => { name => $name, source => { type => 'string', pattern => $SOURCE_NAME } },
                patternProperties    => { '(?!(?:name|source)\z)' . $HOST => { %$name, nullable => 1 } },
            },
        ],
    };
}

our $URL = { type => 'string', pattern => '\Ahttps?://[^/\s]+\S*\z' };

our %SOURCE = (
    deb => {
        type                 => 'object',
        required             => [qw{name uri suites components key fingerprint}],
        additionalProperties => 0,
        properties           => {
            name          => { type => 'string', pattern => $SOURCE_NAME },
            uri           => $URL,
            key           => $URL,
            suites        => list_of( { type => 'string', pattern => '\A(?:[^\s{}]|\{codename\})+\z' } ),
            components    => { type => 'array',  items   => { type => 'string', pattern => '\A\S+\z' } },
            architectures => { type => 'array',  items   => { type => 'string', pattern => '\A[a-z0-9]+\z' } },
            fingerprint   => { type => 'string', pattern => '\A[0-9A-Fa-f]{40}\z' },
            distros       => list_of( { type => 'string', pattern => $HOST } ),
            pin           => {
                type                 => 'object',
                required             => ['priority'],
                additionalProperties => 0,
                properties           => { priority => { type => 'integer' }, packages => { type => 'string', pattern => '\A\S+\z' } },
            },
        },
    },
);

our $SCHEMA = {
    type       => 'object',
    properties => {
        $PACKAGES => {
            type                 => 'object',
            additionalProperties => 0,
            patternProperties    => {
                $DEPENDENCY => {
                    type => 'object',
                    more_than( test => 'names no packager' ),
                    additionalProperties => 0,
                    properties           => {
                        test => { type => 'string', pattern => '\A[^\n]*\S[^\n]*\z' },
                        map { $_ => entry_of( $PACKAGE_NAME{$_} ) } keys %PACKAGE_NAME,
                    },
                    patternProperties => { '(?!(?:' . join( q{|}, sort keys %PACKAGE_NAME ) . ')\z)' . $PACKAGER => entry_of($ANY_PACKAGE_NAME) },
                },
            },
        },
        $SOURCES => {
            type                 => 'object',
            additionalProperties => 0,
            properties           => { map { $_ => list_of( $SOURCE{$_} ) } keys %SOURCE },
        },
    },
};

# The mapping of metamerge.yml, or an empty one when there is none.  Dies when the file does not parse.
my sub document_of ($snapshot) {
    my $text = $snapshot->content($FILE) // return {};
    return Dist::Conformance::Schema::parse_yaml( $text, $FILE );
}

my sub declaration_of ($document) { return { packages => $document->{$PACKAGES} // {}, sources => $document->{$SOURCES} // {} } }

# The errors of the schema, or else what it cannot say, because it compares one part of the document with
# another: that the sources and the entries that name them agree.
my sub errors_of ($document) {
    my @errors = Dist::Conformance::Schema::errors( $document, $SCHEMA );
    return @errors if @errors;
    my ( $packages, $sources ) = @{ declaration_of($document) }{qw{packages sources}};
    my %named;
    for my $dependency ( sort keys %$packages ) {
        my @packagers = grep { $_ ne 'test' } sort keys %{ $packages->{$dependency} };
        for my $packager ( grep { ref $packages->{$dependency}{$_} } @packagers ) {
            my $entry = $packages->{$dependency}{$packager};
            next if !defined $entry->{source};
            $named{$packager}{ $entry->{source} } = 1;
            if ( List::Util::none { $_->{name} eq $entry->{source} } @{ $sources->{$packager} // [] } ) {
                push @errors, "/$PACKAGES/$dependency/$packager/source: $entry->{source} is not a source in $SOURCES/$packager";
            }
        }
    }
    for my $packager ( sort keys %$sources ) {
        my %seen;
        for my $index ( 0 .. $#{ $sources->{$packager} } ) {
            my $source = $sources->{$packager}[$index];
            push @errors, "/$SOURCES/$packager/$index/name: $source->{name} is the name of another source too" if $seen{ $source->{name} }++;
            push @errors, "/$SOURCES/$packager/$index: no dependency names $source->{name} as its source"      if !$named{$packager}{ $source->{name} };
        }
    }
    return @errors;
}


sub declared ( $, $from ) {
    my $snapshot = builtin::blessed($from) && $from->isa('Dist::Conformance::Snapshot') ? $from : Dist::Conformance::Snapshot::Directory->new( root => $from );
    my $document = document_of($snapshot);
    my @errors   = errors_of($document);
    Dist::Conformance::Schema::refuse( $FILE, @errors ) if @errors;
    return declaration_of($document);
}


sub resolve ( $, $declared, %host ) {
    my ( $packager, $distro, $release, $codename ) = @host{qw{packager distro release codename}};
    die "resolve needs a packager\n" if !defined $packager;
    my @keys    = ( ( defined $distro && defined $release ? "$distro/$release" : () ), ( defined $distro ? $distro : () ), 'name' );
    my %on_host = map { $_ => 1 } grep { $_ ne 'name' } @keys;
    my %source  = map { $_->{name} => $_ } @{ $declared->{sources}{$packager} // [] };

    my ( @needs, @unresolved );
    for my $name ( sort keys %{ $declared->{packages} } ) {
        my $dependency = $declared->{packages}{$name};
        my $entry      = $dependency->{$packager};
        my %need       = ( name => $name, package => $entry, source => undef, test => $dependency->{test} );
        if ( ref $entry ) {
            my ($key) = grep { exists $entry->{$_} } @keys;
            $need{package} = defined $key ? $entry->{$key} : undef;
            $need{source}  = $entry->{source} if defined $need{package};
            $entry         = undef            if !defined $key;
        }
        my $source = defined $need{source} ? $source{ $need{source} } : undef;
        if ( !defined $entry || ( $source && $source->{distros} && !List::Util::any( sub { $on_host{$_} }, @{ $source->{distros} } ) ) ) {
            push @unresolved, $name;
            next;
        }
        push @needs, \%need;
    }

    my @sources;
    for my $name ( List::Util::uniq( grep { defined } map { $_->{source} } @needs ) ) {
        my %resolved = %{ $source{$name} };
        delete $resolved{distros};
        $resolved{suites} = [
            map {
                my $suite = $_;
                die "The source $name needs the codename of the host, for the suite $suite\n" if index( $suite, '{codename}' ) >= 0 && !defined $codename;
                $suite =~ s/\{codename\}/$codename/gr;
            } @{ $resolved{suites} }
        ];
        push @sources, \%resolved;
    }
    return {
        needs      => \@needs,
        packages   => [ List::Util::uniq( grep { defined } map { $_->{package} } @needs ) ],
        sources    => \@sources,
        programs   => [ grep { defined } map { $_->{test} } @needs ],
        unresolved => \@unresolved,
    };
}


sub os_release ($text) {
    my %variables;
    for my $line ( split /\n/, $text ) {
        my ( $name, $value ) = $line =~ m/\A\s*([[:alpha:]_]\w*)=(.*?)\s*\z/ or next;
        my ($double) = $value =~ m/\A"((?:[^"\\]|\\.)*)"\z/;
        my ($single) = $value =~ m/\A'([^']*)'\z/;
        $variables{$name} = defined $double ? $double =~ s/\\(.)/$1/gr : $single // $value;
    }
    return \%variables;
}


sub check ( $, $snapshot ) {
    return ( 'pass', "there is no $FILE, so it needs no system packages" ) if !$snapshot->contains($FILE);
    my $document = eval { document_of($snapshot) } // return ( 'fail', Dist::Conformance::Schema::first_line($@) );
    my @errors   = errors_of($document);
    return ( 'fail', "$FILE is not valid: " . join '; ', @errors ) if @errors;
    my $declaration = declaration_of($document);
    my $sources     = $declaration->{sources};
    my @said        = ( map { Lingua::EN::Inflect::NO( "$_ source", scalar @{ $sources->{$_} } ) } sort keys %$sources );
    unshift @said, Lingua::EN::Inflect::NO( 'dependency', scalar keys %{ $declaration->{packages} } ) if %{ $declaration->{packages} };
    return ( 'pass', "$FILE declares no system packages" ) if !@said;
    my $last = pop @said;
    return ( 'pass', "$FILE declares " . ( @said ? join( ', ', @said ) . " and $last" : $last ) );
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Check::SystemPackages - The system packages that a repository declares in metamerge.yml, validated, and resolved for a host

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use 5.040;
    use Dist::Conformance::Check::SystemPackages;

    my $declared = Dist::Conformance::Check::SystemPackages->declared('/bogus/checkout');
    my $host     = Dist::Conformance::Check::SystemPackages->resolve(
        $declared,
        packager => 'deb',
        distro   => 'ubuntu',
        release  => '24.04',
        codename => 'noble',
    );
    die "No package for @{ $host->{unresolved} }\n" if @{ $host->{unresolved} };
    say for @{ $host->{packages} };

=head1 DESCRIPTION

CPAN has no field for a package of the operating system, such as F<ffmpeg> or
F<libmagic-dev>, that a distribution needs.  So a repository declares them in
F<metamerge.yml>, the file that C<[MetaMergeFile]> of Dist::Zilla merges into
F<META.json>.  C<x_system_packages> names each dependency, and says which
package gives it for each packager.  C<x_system_sources> names the
third-party archives that some of the packages come from:

    x_system_packages:
      FooLib:
        deb:
          name: libfoo-devel
          ubuntu/24.04: libfoo-dev
          debian/13: ~
        rpm: libfoo-devel
      ffmpeg:
        deb:
          name: ffmpeg
          source: jellyfin
        test: ffmpeg -version
    x_system_sources:
      deb:
        - name: jellyfin
          uri: https://repo.test.test/ubuntu
          suites: ['{codename}']
          components: [main]
          key: https://repo.test.test/key.gpg
          fingerprint: 0123456789ABCDEF0123456789ABCDEF01234567
          distros: [ubuntu/24.04]

The declaration says what a host must install.  This check does not ask what
a host has installed.  It reads a snapshot, which can be of a repository that
is not on this machine, and does not run the tests.  Other code installs the
packages: it reads them with L</declared> and L</resolve>, or with
C<conformance packages> (see L<conformance>).

=head2 A dependency

A key of C<x_system_packages> is the name of a dependency: a letter or a
digit, then letters, digits, C<_>, C<.>, C<+>, C<:> and C<->, such as
C<Foo::Lib> or C<ffmpeg>.  The name is for people and for reports.  No
packager reads it.

Its value is a mapping.  Each key other than C<test> is the name of a
packager: a lowercase letter, then lowercase letters and digits, as
C<< Provisioner::Packager->named >> takes it.  A dependency has one packager at
least.  C<test> is optional.  It is one command line that must exit 0 once the
package is installed, because a package that is installed is not yet a
program that runs.  It is one line that is not blank.

=head2 An entry

The value of a packager is the entry of the dependency for that packager.  It
is a package name, which applies to every host, or a mapping with these keys:

=over

=item name

The package on a host that no other key matches.

=item C<DISTRO>, C<DISTRO/RELEASE>

The package on that distro, or on that release of it.  C<DISTRO> is the C<ID>
of F</etc/os-release>, such as C<ubuntu> or C<debian>, and C<RELEASE> is its
C<VERSION_ID>, such as C<24.04> or C<13>.  Both are lowercase letters,
digits, C<.>, C<_> and C<->.  A null value says that the host needs no
package for the dependency.

=item source

Optional.  The name of the archive in C<x_system_sources> of the same
packager that the package comes from.

=back

The mapping has C<name>, or a C<DISTRO> or C<DISTRO/RELEASE> key, or both.
For a host, the most specific key wins: C<DISTRO/RELEASE>, then C<DISTRO>,
then C<name>.

=head2 What a package name is

A package name must be a plain name, and not an expression that the packager
reads in some other way, such as C<foo=1.2>, C<foo/sid> or two names.  Each
packager has its own rule:

=over

=item deb

The rule of the Debian policy: lowercase letters, digits, C<+>, C<-> and C<.>,
at least two characters, starting with a letter or a digit.  The name must not
end in C<->, because C<apt-get install foo-> removes F<foo>.

=item any other packager

Letters, digits, C<+>, C<.>, C<_> and C<->, starting with a letter or a digit,
and not ending in C<->, until the packager has a rule of its own here.

=back

=head2 A source

C<x_system_sources> has a list of sources for each packager.  Only C<deb>
takes sources.  A source of C<deb> is an apt archive, with the keys of a source
of C<Provisioner::Packager::Deb>, and two more:

=over

=item name

The name that an entry gives as C<source>, and the base name of the files of
the source: lowercase letters, digits, C<.> and C<->, from a letter or a
digit.  Two sources of a packager do not have the same name.

=item C<uri>, C<key>

The archive, and the URL of its signing key, as C<http> or C<https>.

=item suites

At least one suite.  C<{codename}> in a suite is replaced by the
C<VERSION_CODENAME> of the host.  No other placeholder is allowed.

=item components

A list of components.

=item architectures

Optional.  A list of architectures: lowercase letters and digits.

=item pin

Optional.  A mapping with an integer C<priority>, and C<packages>, a glob of
package names.

=item fingerprint

Required.  The full fingerprint of the signing key, as 40 hex digits.  The
archive gets the trust of root on the host, and a key URL can serve another
key later, so the installer refuses a key with another fingerprint.

=item distros

Optional.  A list of C<DISTRO> and C<DISTRO/RELEASE>, as in L</An entry>.  The
source applies only to a host that one of them matches.  Default every host.

=back

Each source is the C<source> of an entry of the same packager.  A source that
no entry names is not valid, because nothing would install from it.

=head1 METHODS

=head2 declared

C<($from)>, a class method.  The validated declaration of a repository, as it
is written: a hash reference with C<packages>, the mapping of
C<x_system_packages>, and C<sources>, the mapping of C<x_system_sources>, such
as

    {
        packages => { ffmpeg => { deb => { name => 'ffmpeg', source => 'jellyfin' }, test => 'ffmpeg -version' } },
        sources  => { deb => [ { name => 'jellyfin', uri => ..., fingerprint => ... } ] },
    }

A repository that declares nothing gives C<< { packages => {}, sources => {} } >>.
L</resolve> gives what one host installs.

C<$from> is a L<Dist::Conformance::Snapshot>, such as a
L<Dist::Conformance::Snapshot::Tree> of a remote repository, or the directory
of a checkout.  Only F<metamerge.yml> is read.

Dies when F<metamerge.yml> does not parse, and when the declaration is not
valid, as L</DESCRIPTION> says.  Then the message starts with
C<metamerge.yml is not valid:>, and gives each error on a line of its own, as
L<Dist::Conformance::Schema/validate> does.

=head2 resolve

C<($declared, %host)>, a class method.  What one host installs, from
C<$declared> as L</declared> returns it.  C<%host> has:

=over

=item packager

Required.  The packager of the host, such as C<deb>.

=item distro, release

The C<ID> and the C<VERSION_ID> of F</etc/os-release>.  Without them, only
C<name> matches an entry, and only a source without C<distros> applies.

=item codename

The C<VERSION_CODENAME> of F</etc/os-release>, for C<{codename}> in a suite.

=back

Returns a hash reference:

    {
        needs      => [ { name => 'FooLib', package => 'libfoo-dev', source => undef, test => undef }, ... ],
        packages   => [ 'libfoo-dev', 'ffmpeg' ],
        sources    => [ { name => 'jellyfin', suites => ['noble'], ... } ],
        programs   => [ 'ffmpeg -version' ],
        unresolved => [ 'BarLib' ],
    }

=over

=item needs

One item for each dependency that resolves on the host, by the sorted name of
the dependency, because a YAML mapping has no order.  C<package> is the
package for the host, or C<undef> when the most specific key is null, so that
the host needs nothing.  C<source> is the name of its source, and C<test> the
test of the dependency, or C<undef>.

=item packages

The packages of C<needs>, in their order, without duplicates.

=item sources

The sources that the packages of C<needs> come from, in their order, once
each, with C<{codename}> filled in and without C<distros>.

=item programs

The tests of C<needs>, in their order.

=item unresolved

The sorted names of the dependencies that do not resolve on the host: those
without an entry for the packager, those whose entry has no key that matches
the host, and those whose source is not for the host.  A host must not go on
without them, so the caller decides what to do, and C<resolve> does not die.

=back

Dies without a packager, and on a source that a package needs and that needs a
codename that C<%host> does not give.

=head2 check

=head1 FUNCTIONS

=head2 os_release

C<($text)>.  The variables of the text of an F</etc/os-release>, as a hash
reference from each name to its value, such as
C<< { ID => 'ubuntu', VERSION_ID => '24.04', VERSION_CODENAME => 'noble' } >>.
A value can be bare, in single quotes, or in double quotes with C<\>
escapes, as the shell reads it.  Blank lines and comments are skipped.

=head1 IN A FLAVOR

    checks:
      SystemPackages: {}

=head1 STATUSES

The check passes when there is no F<metamerge.yml>, when it declares nothing,
and when the declaration is valid, because most repositories need no system
packages.  It fails when F<metamerge.yml> does not parse, or when the
declaration is not valid.  The update changes nothing: what a repository needs
is its own choice.

=head1 CONFIGURATION

None, other than L<Dist::Conformance::Check/THE KEYS THAT EVERY CHECK TAKES>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Conformance|Dist::Conformance>

=item *

L<Dist::Conformance::Check>

=item *

L<conformance>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/Dist-Conformance/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

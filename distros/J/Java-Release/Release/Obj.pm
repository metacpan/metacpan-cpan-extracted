package Java::Release::Obj;

use strict;
use warnings;

use Mo qw(is required);

our $VERSION = 0.03;

# Computer architecture
has arch => (
	is => 'ro',
	required => 1,
);

# Interim version.
has interim => (
	is => 'ro',
);

# Operating system.
has os => (
	is => 'ro',
	required => 1,
);

# Patch version.
has patch => (
	is => 'ro',
);

# Release version.
has release => (
	is => 'ro',
	required => 1,
);

# Update version.
has update => (
	is => 'ro',
);

1;

__END__

=pod

=encoding utf8

=head1 NAME

Java::Release::Obj - Data object for Java::Release.

=head1 SYNOPSIS

 use Java::Release::Obj;

 my $obj = Java::Release::Obj->new(%params);
 my $arch = $obj->arch
 my $interim = $obj->interim;
 my $os = $obj->os;
 my $patch = $obj->patch;
 my $release = $obj->release;
 my $update = $obj->update;

=head1 METHODS

=head2 C<constructor>

 my $obj = Java::Release::Obj->new(%params);

Constructor.

Returns object.

=over 8

=back

=head2 C<arch>

 my $arch = $obj->arch

Get architecture.

Returns string.

=head2 C<interim>

 my $interim = $obj->interim;

Get interim version number.

Returns integer.

=head2 C<os>

 my $os = $obj->os;

Get operating system.

Returns string.

=head2 C<patch>

 my $patch = $obj->patch;

Get patch version number.

Returns integer.

=head2 C<release>

 my $release = $obj->release;

Get release version number.

Returns integer.

=head2 C<update>

 my $update = $obj->update;

Get update version number.

Returns integer.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Data::Printer;
 use Java::Release::Obj;

 my $obj = Java::Release::Obj->new(
         arch => 'i386',
         os => 'linux',
         release => 1,
 );

 p $obj;

 # Output like:
 # Java::Release::Obj  {
 #     Parents       Mo::Object
 #     public methods (0)
 #     private methods (0)
 #     internals: {
 #         arch      "i386",
 #         os        "linux",
 #         release   1
 #     }
 # }

=head1 DEPENDENCIES

L<Mo>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Java-Release>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut

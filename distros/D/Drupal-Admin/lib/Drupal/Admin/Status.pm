#################################################################
# Drupal::Admin::Status Package
#################################################################

package Drupal::Admin::Status;

use Moose;
use Moose::Util::TypeConstraints;

subtype 'StatusType'
  => as 'Str'
  => where { $_ eq 'info' || $_ eq 'ok' || $_ eq 'warning' || $_ eq 'error' }
  => message { 'The type must be one of [info|ok|warning|error]' };

# 'ok', 'warning', 'error'
has 'type' => (
	       is => 'ro',
	       isa => 'StatusType',
	       required => 1
	      );

has 'title' => (
	       is => 'ro',
	       isa => 'Str',
	       required => 1
	      );

has 'status' => (
	       is => 'ro',
	       isa => 'Str',
	       required => 1
	      );

# Only warnings and errors have comments
has 'comment' => (
	       is => 'ro',
	       isa => 'Str',
	      );


no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME 

Drupal::Admin::Status - simple object representing elements of the
drupal status page

=head1 METHODS

=over 4

B<type>

Type can be one of C<info>, C<ok>, C<warning> or C<error>

B<title>

Title of status section

B<status>

Short status message

B<comment>

Optional additional comment (used mostly by warnings and errors)

=back

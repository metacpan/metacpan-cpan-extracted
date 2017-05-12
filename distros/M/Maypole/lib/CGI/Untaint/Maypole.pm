package CGI::Untaint::Maypole;

use strict;
use warnings;
our $VERSION = '0.01';
use base 'CGI::Untaint';
use Carp;

=head1 NAME

CGI::Untaint::Maypole - Use instead of CGI::Untaint. Based on CGI::Untaint

=head1 SYNOPSIS

  use CGI::Untaint::Maypole;
  my $h = CGI::Untaint::Maypole->new($params);
  $value = $h->extract(-as_printable => 'name);

  if ($h->error =~ /No input for/) {
 	# caught empty input now handle it
		....
  }
  if ($h->raw_data->{$field} eq $object->$field) {
    # Raw data same as database data. Perhaps we should not update field
	...
  }

=head1 DESCRIPTION

This patches some issues I have with CGI::Untaint. You still need it installed
and you install handlers the same.

1) Instead of passing the empty string to the untaint handlers and relying on
them to handle it to everyone's liking, it seems better 
to have CGI::Untaint just say "No input for field" if the field is blank.

2) It  adds the method C<raw_data> to the get back the parameters the handler
was created with. 

=cut

=head2 raw_data

Returns the parameters the handler was created with as a hashref

=cut

sub raw_data { 
	return shift->{__data};
}

# offending method ripped from base and patched
sub _do_extract {
	my $self = shift;

	my %param = @_;

	#----------------------------------------------------------------------
	# Make sure we have a valid data handler
	#----------------------------------------------------------------------
	my @as = grep /^-as_/, keys %param;
	croak "No data handler type specified"        unless @as;
	croak "Multiple data handler types specified" unless @as == 1;

	my $field      = delete $param{ $as[0] };
	my $skip_valid = $as[0] =~ s/^(-as_)like_/$1/;
	my $module     = $self->_load_module($as[0]);

	#----------------------------------------------------------------------
	# Do we have a sensible value? Check the default untaint for this
	# type of variable, unless one is passed.
	#----------------------------------------------------------------------

	################# PETER'S PATCH #####################
	my $raw = $self->{__data}->{$field} ;
	die "No parameter for '$field'\n" if !defined($raw);
	die "No input for '$field'\n" if $raw eq '';
    #####################################################


	my $handler = $module->_new($self, $raw);

	my $clean = eval { $handler->_untaint };
	if ($@) {    # Give sensible death message
		die "$field ($raw) is in invalid format.\n"
			if $@ =~ /^Died at/;
		die $@;
	}

	#----------------------------------------------------------------------
	# Are we doing a validation check?
	#----------------------------------------------------------------------
	unless ($skip_valid) {
		if (my $ref = $handler->can('is_valid')) {
			die "$field ($raw) is in invalid format.\n"
				unless $handler->is_valid;
		}
	}

	return $handler->untainted;
}

=head1 BUGS

None known yet.

=head1 SEE ALSO

L<perlsec>. L<CGI::Untaint>.

=head1 AUTHOR

Peter Speltz.

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
   bug-Maypole@rt.cpan.org

=head1 COPYRIGHT and LICENSE

Copyright (C) 2006 Peter Speltz.  All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

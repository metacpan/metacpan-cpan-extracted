package Decl::Semantics::Value;

use warnings;
use strict;

use base qw(Decl::Node);
use Decl::Semantics::Code;

=head1 NAME

Decl::Semantics::Value - implements a named value in an event context

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This class serves two purposes: first, it's an example of what a semantic node class should look like, and second, it
will probably end up being the class that builds most of the code references in a declarative program.

=head2 defines(), tags_defined()

Called by Decl::Semantics during import, to find out what xmlapi tags this plugin claims to implement.

=cut
sub defines { ('value'); }
sub tags_defined { Decl->new_data(<<EOF); }
value (body=vanilla)
EOF

=head2 build_payload

The C<build> function is then called when this object's payload is built (i.e. in the stage when we're adding semantics to our
parsed syntax).

The parent's payload will always have been created by the time this function is called.

=cut

sub build_payload {
   my ($self, $is_event) = @_;
   return $self if $self->{built};
   my $cx = $self->parent;
   
   Decl::Semantics::Code::build_payload($self, 0, 'this', 'key', 'value');
   $self->{built} = 1;
   
   if ($self->{callable}) {
      $self->{callable} = 0;
      $cx->register_varhandler ($self->name, $self->{sub});
   }
   
   $cx->{hashtie}->just_store ($self->name, $self->label);
   return $self;
}


=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-decl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Decl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Decl::Semantics::Value

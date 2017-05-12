package Maypole::Component;
use base 'Maypole';
use strict;
use warnings;
our $VERSION = '0.03';
use URI; use URI::QueryParam;

sub component {
    my ($r, $path) = @_;
    my $self = bless { config => $r->config, parent => $r }, "Maypole::Component";
    my $url = URI->new($path);
    $self->{path} = $url->path;
    $self->parse_path;
    $self->{query} = $url->query_form_hash;
    $self->handler_guts;
    $self->{output};
}

sub get_template_root { shift->{parent}->get_template_root }
sub view_object { shift->{parent}->view_object }

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Maypole::Component - Run Maypole sub-requests as components

=head1 SYNOPSIS

  package BeerDB;
  use base qw(Maypole::Component Apache::MVC);


    [% request.component("/beer/view_as_component/20") %]

=head1 DESCRIPTION

This subclass of Maypole allows you to integrate the results of a Maypole
request into an existing request. You'll need to set up actions and templates
which return fragments of HTML rather than entire pages, but once you've
done that, you can use the C<component> method of the Maypole request object
to call those actions. You may pass a query string in the usual URL style.
You should not fully qualify the Maypole URLs.

=head1 SEE ALSO

http://maypole.simon-cozens.org/

=head1 AUTHOR

Simon Cozens, E<lt>simon@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Simon Cozens

=cut

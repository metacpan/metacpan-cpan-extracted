package Maypole::Plugin::LinkTools;

use warnings;
use strict;

our $VERSION = '0.21';

=head1 NAME

Maypole::Plugin::LinkTools - convenient link construction

=head1 SYNOPSIS

    use Maypole::Application qw( LinkTools );
    
    #...
    
    print $request->maybe_link_view( $thing );
    
    print $request->maybe_many_link_views( @things );
    
    print $request->link( table      => $table,
                          action     => $action,        # called 'command' in the original link template
                          additional => $additional,    # optional - generally an object ID
                          label      => $label,
                          );
                          
    print $request->make_path( table      => $table,
                               action     => $action,        # called 'command' in the original link template
                               additional => $additional,    # optional - generally an object ID
                               );
    
                               
=head1 DESCRIPTION

Provides convenient replacements for the C<link> and C<maybe_link_view> templates, and a new 
C<maybe_many_link_views> method. 

Centralises all path manipulation, so that a new URI scheme can be implemented site-wide by 
overriding just two methods (C<Maypole::parse_path()> and C<Maypole::Plugin::LinkTools::make_path()>).

For ease of use with the Template Toolkit, C<make_path>, C<link> and
C<link_view> will also accept a hashref of arguments. For example:

    print $request->make_path({ table      => $table,
                                action     => $action,
                                additional => $additional,
                             });

=head1 METHODS

=over 4

=item make_path( %args or \%args )

This is the counterpart to C<Maypole::parse_path>. It generates a path to use in links, 
form actions etc. To implement your own path scheme, just override this method and C<parse_path>.

    %args = ( table      => $table,
              action     => $action,        # called 'command' in the original link template
              additional => $additional,    # optional - generally an object ID
              );

C<id> can be used as an alternative key to C<additional>.

=cut

# TODO:
# C<$additional> can be a string, an arrayref, or a hashref. An arrayref is expanded into extra 
# path elements, whereas a hashref is translated into a query string. 
sub make_path
{
    my $r = shift;
    my %args = (@_ == 1 && ref $_[0] && ref $_[0] eq 'HASH') ? %{$_[0]} : @_;

    do { die "no $_" unless $args{ $_ } } for qw( table
                                                  action
                                                  );    

    my $base = $r->config->uri_base;
    $base = '' if $base eq '/';

    $args{additional} ||= $args{id};
    my $add = $args{additional} ? "/$args{additional}" : '';
    
    return sprintf '%s/%s/%s%s', $base, $args{table}, $args{action}, $add;
}
        
=item link( %args or \%args )

Returns a link, calling C<make_path> to generate the path. 

    %args = ( table      => $table,
              action     => $action,        # called 'command' in the original link template
              additional => $additional,    # optional - generally an object ID
              label      => $label,
              );

The table can be omitted and defaults to that of the request's model.
C<id> can be used as an alternative key to C<additional>.

=cut

sub link
{
    my $r = shift;
    my %args = (@_ == 1 && ref $_[0] && ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
    
    $args{table} ||= $r->model_class->table;
    $args{label} ||= '...'; # in case a stringify column is left empty
    
    foreach my $key ( qw( table action ) )
    { 
        die sprintf "link: no %s (got table: %s action: %s label: %s)",
            $key, $args{table} || '', $args{action} || '', $args{label} || '' 
                unless $args{ $key };
    } 
    
    my $path = $r->make_path( %args );
    
    return sprintf '<a href="%s">%s</a>', $path, $args{label};
}

=item link_view( $thing or %args or \%args )

Build a link to the C<view> action of the given item.
If passed a Maypole request object, builds a link to its C<view> action. 

    print $request->link_view( $maypole_request );
    
    print $request->link_view( table      => $table,
                               label      => $label,
                               additional => $id,
                               );
                               
=cut

sub link_view
{
    my $r = shift;
    
    my %args;
    
    if ( @_ == 1 )
    {
        die "single argument to link_view() must be a reference (got $_[0])" unless ref $_[0];
    
        if ( ref $_[0] eq 'HASH' )
        {
            %args = %{ $_[0] };
        }
        elsif ( UNIVERSAL::isa( $_[0], 'Maypole::Model::Base' ) )
        {
            my $object = shift;
            
            my $str = ''.$object;
            warn sprintf "%s (id: %s) object has no data for stringification", ref($object), $object->id unless $str;
            $str ||= '...';
            
            %args = ( table      => $object->table,
                      additional => $object->id,
                      label      => $str,
                      );
        }
        else
        {
            die "unsuitable single argument to link_view (got $_[0]) - need hashref or Maypole/CDBI object";
        }
    }
    else
    {
        %args = @_;
    }
    
    return $r->link( %args, action => 'view' );
}

=item maybe_link_view( $thing )

Returns stringified C<$thing> unless it isa C<Maypole::Model::Base> object, in which case 
a link to the view template for the object is returned.

=cut

sub maybe_link_view
{
    my ( $r, $thing ) = @_; 
    
    if ( ref $thing and UNIVERSAL::isa( $thing, 'Maypole::Model::Base' ) )
    {
        return $r->link_view( $thing );
    }
    else
    {
        return ''.$thing;
    }    
}

=item maybe_many_link_views

Runs multiple items through C<maybe_link_view>, returning a list.

=cut

# if the accessor is for a has_many relationship, it might return multiple items, which 
# would each be passed individually to maybe_link_view(), and then each would go in its 
# own column. Instead, we want a list of items to put in a single cell.
sub maybe_many_link_views
{
    my ( $r, @values ) = @_;
    
    return map { $r->maybe_link_view( $_ ) } @values;
}



=back

=head1 AUTHOR

David Baird, C<< <cpan@riverside-cms.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-maypole-plugin-linktools@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Maypole-Plugin-LinkTools>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 David Baird, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Maypole::Plugin::LinkTools

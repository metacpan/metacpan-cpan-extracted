package HTTP::DAV::Browse;

=head1 NAME

HTTP::DAV::Browse - browse the WebDAV tree

=head1 SYNOPSIS

    my $browser = HTTP::DAV::Browse->new('base_uri' => $url);
    my %lsd = $browser->ls_detailed('/');
    my @files = $browser->ls('/');

=head1 DESCRIPTION

For the moment L<HTTP::DAV::Browse> allows to list WebDAV folders and
gather detailed information (properties) about the files inside.

Can be used on Subversion WebDAV repositories.

NOTE: for our https+password protected Subversion repository, I hat to set all
username+password+realm to make it work and not complain that the
requests are not authenticated.

=cut

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;
use HTTP::DAV 0.38;
use URI;

our $VERSION = '0.05';

=head1 PROPERTIES

    base_uri
    username
    password
    realm

=cut

subtype 'Object.HTTP.DAV' => as class_type('HTTP::DAV');
subtype 'Object.URI' => as class_type('URI');
coerce 'Object.URI'
    => from 'Str'
    => via { URI->new($_) };

has '_dav'     => (is => 'ro', isa => 'Object.HTTP.DAV', lazy => 1, default => sub { $_[0]->_dav_init });
has 'base_uri' => (is => 'rw', isa => 'Object.URI', required => 1, coerce => 1 );
has 'username' => (is => 'rw', isa => 'Str|Undef');
has 'password' => (is => 'rw', isa => 'Str|Undef');
has 'realm'    => (is => 'rw', isa => 'Str|Undef');

=head1 METHODS

=head2 new()

Object constructor. Requires 'base_uri' argument.

=cut

sub _dav_init {
    my $self = shift;

    my $dav = new HTTP::DAV;    
    $dav->credentials(
        $self->username,
        $self->password,
        $self->base_uri,
        $self->realm,
    );
  
    $dav->open( $self->base_uri )
      or die("Couldn't open ".$self->base_uri.": " .$dav->message . "\n");
    
    return $dav;
}
sub _base_path {
    my $self = shift;
    return $self->base_uri->path;
}

=head2 ls($path)

For given C<$path> (that is prepended by C<<$self->base_uri>>) returns
array of files.

Throws exception for non existing paths.

=cut

sub ls {
    my $self = shift;
    return map { $_->{'rel_uri'} } $self->ls_detailed(@_);
}


=head2 ls_detailed($path)

For given C<$path> (that is prepended by C<<$self->base_uri>>) returns
array of hashes with file details. Example:

     {
        'baseline-relative-path' => 'trunk/SVGraph',
        'version-name' => '69',
        'version-controlled-configuration' => '<D:href>/svgraph/!svn/vcc/default</D:href>',
        'creationdate' => 'Mon, 19 Nov 2007 08:01:47 GMT',
        'short_ls' => 'Listing of http://svn.comsultia.com/svgraph/trunk/SVGraph/
',
        'getlastmodified' => 'Mon, 19 Nov 2007 08:01:47 GMT',
        'lastmodifiedepoch' => 1195459307,
        'short_props' => '<dir>',
        'getcontenttype' => 'text/html; charset=UTF-8',
        'checked-in' => '<D:href>/svgraph/!svn/ver/69/trunk/SVGraph</D:href>',
        'repository-uuid' => '05c03c3c-be17-0410-b9f1-b57ecf2f02e2',
        'display_date' => 'Nov 19  2007',
        'resourcetype' => 'collection',
        'creationepoch' => '1195459307.58319',
        'creator-displayname' => 'rfordinal',
        'long_ls' => 'URL: http://svn.comsultia.com/svgraph/trunk/SVGraph/
            --- stripped ---
        ',
        'getetag' => 'W/"69//trunk/SVGraph"',
        'rel_uri' => bless( do{\(my $o = 'SVGraph/')}, 'URI::http' ),
        'deadprop-count' => '0',
        'lastmodifieddate' => 'Mon, 19 Nov 2007 08:01:47 GMT'
    }

Throws exception for non existing paths.

=cut
sub ls_detailed {
    my $self = shift;
    my $path = shift;
    
    die 'path is required argument'
        if not defined $path;
    
    my $dav = $self->_dav;
    
    # find propertis on $path
    my $resources = $dav->propfind($self->_base_path.$path, 1);
    die $dav->message
        if not $resources;

    # get list of resources
    my $resources_list = $resources->get_resourcelist;
    
    # nothing to do if no resources found
    return
        if not $resources_list;

    # return array of { all properties }
    return
        map { $_->{'_properties'} }
        $resources_list->get_resources
    ;
}

'..., nebo je po mně a já mám voskované boty, ráno co ráno stejné probuzení do nicoty.';


__END__

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-http-dav-browse at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-DAV-Browse>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTTP::DAV::Browse


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-DAV-Browse>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTTP-DAV-Browse>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTTP-DAV-Browse>

=item * Search CPAN

L<http://search.cpan.org/dist/HTTP-DAV-Browse>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

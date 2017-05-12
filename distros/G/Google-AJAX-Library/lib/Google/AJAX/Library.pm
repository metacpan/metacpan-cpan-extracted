package Google::AJAX::Library;
BEGIN {
  $Google::AJAX::Library::VERSION = '0.022';
}
# ABSTRACT: Access the Google AJAX Libaries API in Perl

use warnings;
use strict;


use Moose;
use Google::AJAX::Library::Carp;

use URI;
use LWP::UserAgent;
use Path::Class;
use HTML::Declare qw/SCRIPT/;

use constant BASE => 'http://ajax.googleapis.com/ajax/libs';
use constant LATEST_VERSION => {qw/
    jquery 1
    prototype 1
    scriptaculous 1
    mootools 1
    dojo 1
/};

$Google::AJAX::Library::VERSION ||= 0;

has uri => qw/is ro/;
has version => qw/is ro/;
has file => qw/is ro/;
has name => qw/is ro/;
has ua => qw/is ro required 1 lazy 1 isa LWP::UserAgent/, default => sub {
    my $ua = LWP::UserAgent->new;
    $ua->agent("Google::AJAX::Library/$Google::AJAX::Library::VERSION (" . $ua->agent . ")");
    return $ua;
};

sub _christen;


sub jquery {
    return _christen jquery => @_;
}

sub jQuery {
    return _christen jquery => @_;
}


sub prototype {
    return _christen prototype => @_;
}


sub scriptaculous {
    return _christen scriptaculous => @_;
}


sub mootools {
    return _christen mootools => @_;
}

sub MooTools {
    return _christen mootools => @_;
}


sub dojo {
    return _christen dojo => @_;
}


sub html {
    my $self = shift;

    return SCRIPT({ type => "text/javascript", src => $self->uri, _ => "", @_ });
}

sub BUILD {
    my $self = shift;
    my $given = shift;
    
    my $uri;
    if ($uri = $given->{uri}) {
    }
    else {
        my $name = $given->{name} or croak "Wasn't given a library name (e.g. jquery, mootools, etc.)";
        my $file = $given->{file};
        ($name, $file) = $self->_name_file($name, $given) unless $file;

        my $base = $given->{base} || BASE;
        my $version = $given->{version} || LATEST_VERSION->{$name} or croak "Wasn't given a library version for $name";

        $uri = join "/", $base, $name, $version, $file;

        $self->{version} = $version;
        $self->{file} = $file;
        $self->{name} = $name;
    }

    $self->{uri} = URI->new($uri);
}

sub _name_file {
    my $self = shift;
    my $name = shift;
    my $extra = shift;

    croak "Wasn't given a library name (e.g. jquery, mootools, etc.)" unless $name;

    my $uncompressed = $extra->{uncompressed} || 0;
    $uncompressed = $uncompressed =~ m/^\s*(?:f(?:alse)?|(?:no?))\s*$/ ? 0 : $uncompressed;
    $uncompressed = $uncompressed ? 1 : 0;
    my $compact = $uncompressed ? 0 : 1;

    $name =~ s/\.js\s*$//i; # Just in case

    my $file;
    if      ($name =~ m/^\s*jquery\s*$/i) {
        $name = "jquery";
        $file = $compact ? "$name.min.js" : "$name.js";
    }
    elsif   ($name =~ m/^\s*script\.?aculo\.?us\s*$/i) {
        $name = "scriptaculous";
        $file = "$name.js";
    }
    elsif   ($name =~ m/^\s*prototype\s*$/i) {
        $name = "prototype";
        $file = "$name.js";
    }
    elsif   ($name =~ m/^\s*mootools\s*$/i) {
        $name = "mootools";
        $file = $compact ? "$name-yui-compressed.js" : "$name.js";
    }
    elsif   ($name =~ m/^\s*dojo\s*$/i) {
        $name = "dojo";
        $file = $compact ? "$name/$name.xd.js" : "$name/$name.xd.js.uncompressed.js";
    }
    else {
        croak "Don't understand library name ($name)";
    }

    return ($name, $file);
}


sub exists {
    my $self = shift;
    return $self->ua->head( $self->uri )->is_success ? 1 : 0;
}


sub request {
    my $self = shift;

    return $self->ua->get($self->uri);
}


sub fetch {
    my $self = shift;

    my $response = $self->request;

    croak "Fetching ", $self->uri, "failed: ", $response->status_line unless $response->is_success;

    return $response->decoded_content unless @_;

    my $to = shift;

    if      (ref $to eq "SCALAR")   { $$to = $response->decoded_content }
    elsif   (ref $to eq "GLOB")     { print $to $response->decoded_content }
    elsif   ($to)                   { Path::Class::File->new($to)->openw->print($response->decoded_content) }
    else                            { croak "Don't know what you want to fetch into" }

    return 1;
}


sub write {
    my $self = shift;

    return $self->fetch(@_);
}

sub _christen {
    my $name = shift;

    my $class;
    if      (blessed $_[0])     { $class = ref shift }
    elsif   ($_[0] =~ m/::/)    { $class = shift }
    else                        { $class = __PACKAGE__ }

    my @new;
    push @new, name => $name;
    push @new, version => shift if @_ && @_ % 2 && ! ref $_[0];
    push @new, @_ if @_ && ! ref $_[0];
    push @new, %{ shift() } if @_ && ref $_[0] eq "HASH";
    
    return $class->new(@new);
}

__PACKAGE__->meta->make_immutable;


1;

__END__
=pod

=head1 NAME

Google::AJAX::Library - Access the Google AJAX Libaries API in Perl

=head1 VERSION

version 0.022

=head1 SYNOPSIS

    use Google::AJAX::Library;

    my $library = Google::AJAX::Library->jquery;

    $library->uri
    # http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js

    $library->html
    # <script src="http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js" type="text/javascript"></script>

You can also fetch or write-out the library content:

    my $library = Google::AJAX::Library->new(name => "mootools", version => "1.8.1");

    my $content = $library->fetch;

    # Into a scalar:
    my $content;
    $library->fetch(\$content)

    # To a filehandle:
    $library->write(\*STDOUT)

    # To a file:
    $library->write("/path/to/library.js")

    # Check if a library exists at http://ajax.googleapis.com
    # This will just do a HEAD request
    $library->exists

=head1 DESCRIPTION

Google::AJAX::Library is a module for accessing the Google AJAX Libaries API via Perl

You can find out more about the API here: http://code.google.com/apis/ajaxlibs/

=head1 METHODS

=head2 Google::AJAX::Library->jquery([ <version>, <extra> ])

=head2 Google::AJAX::Library->jQuery([ <version>, <extra> ])

Returns a jQuery library object of the given version

If no version is given or the given version is 0, then the latest version (1) will be used

You can pass through "uncompressed = 1" to get the non-compacted .js

For example:

    my $library = Google::AJAX::Library->jQuery(1.2, uncompressed => 1)

=head2 Google::AJAX::Library->prototype([ <version> ])

Returns a prototype library object of the given version

If no version is given or the given version is 0, then the latest version (1) will be used

A compressed .js is not offered at this time

=head2 Google::AJAX::Library->scriptaculous([ <version> ])

Returns a script.aculo.us library object of the given version

If no version is given or the given version is 0, then the latest version (1) will be used

A compressed .js is not offered at this time

=head2 Google::AJAX::Library->mootools([ <version>, <extra> ])

=head2 Google::AJAX::Library->MooTools([ <version>, <extra> ])

Returns a MooTools library object of the given version

If no version is given or the given version is 0, then the latest version (1) will be used

You can pass through "uncompressed = 1" to get the non-compacted .js

=head2 Google::AJAX::Library->dojo([ <version>, <extra> ])

Returns a Dojo library object of the given version

If no version is given or the given version is 0, then the latest version (1) will be used

You can pass through "uncompressed = 1" to get the non-compacted .js

=head2 $library->uri

Returns the L<URI> for $library

=head2 $library->version

Returns the version of $library

=head2 $library->name

Returns the name of $library (e.g. jquery, scriptaculous, etc.)

=head2 $library->file

Returns the filename of $library (e.g. jquery.min.js, dojo/dojo.xd.js, etc.)

=head2 $library->html

Returns a properly formatted HTML <script></script> entry for $library

=head2 $library->exists

Returns 1 if the $library (at the URI, including the specified version) exists at http://ajax.googleapis.com/

Returns 0 otherwise

This method uses a HEAD request to do the checking

=head2 $library->request

Returns the L<HTTP::Response> of the GET request for $library

=head2 $library->fetch([ <to> ])

Attempts to GET $library

Returns the L<HTTP::Response> decoded content If <to> is not given

If <to> is a SCALAR reference then the content will be put into <to>

This method is synonymous/interchangeable with C<write>

=head2 $library->write( <to> )

Attempts to GET $library

If <to> is a GLOB reference then the content will be printed to <to>

If <to> is a filename (or Path::Class::File object) then the content will be printed to the filename specified

This method will croak if $library couldn't be gotten from Google (e.g. 404)

This method is synonymous/interchangeable with C<fetch>

=head1 SEE ALSO

L<http://code.google.com/apis/ajaxlibs/>

L<JS::jQuery::Loader>

L<JS::YUI::Loader>

=head1 AUTHOR

  Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


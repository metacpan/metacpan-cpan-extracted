package Gantry::Plugins::Static;

use strict; use warnings;

use File::Spec;
use MIME::Types 'by_suffix';
use Gantry::Init;

use base 'Exporter';

our @EXPORT = qw( do_static );

#-----------------------------------------------------------
# do_static
#-----------------------------------------------------------
sub do_static {
    my( $self, @path ) = @_;

    $self->template_disable( 1 );

    my $tmpl_install_dir = '';
    eval {
        $tmpl_install_dir = Gantry::Init->base_root();
    };
        
    my @base_dirs = split( ":", ( $self->root() . ":" . $tmpl_install_dir ) );
        
    my $filename = pop( @path );
    my $path = File::Spec->catfile( @path, $filename );
    
    foreach ( @base_dirs ) {
        die "$path is a directory" if ( -d "${_}/$path" );
            
        if ( -e "${_}/$path" ) {
            open( FH, "${_}/$path" ) or die $!;
            my $d;
            while( <FH> ) { $d .= $_; }

            my ( $mediatype, $encoding ) = by_suffix( $filename );
            $self->content_type( ( $mediatype || 'text/plain' ) );
        
            return( $d );
        }
    }
    
    die "not found $path\n";
    
}

1;

__END__

=head1 NAME

Gantry::Plugins::Static - Static file method

=head1 SYNOPSIS

    <Perl>
        # ...
        use MyApp qw{ -Engine=CGI -TemplateEngine=TT Static };
    </Perl>
    
    or
    
    use Gantry::Plugins::Static;


=head1 DESCRIPTION

This plugins mixes in a do_static method that serves static files from disk.

This plugin grabs everything after "/static" and  walks the applications
root directories and delivers the file with the correct mime type.

   root => html:html/templates:../root

   /static/dir1/dir2/somefile.ext

will crawl html, html/templates, and ../root in the order that the appear
in the list.

It will also search the directory where you installed the default Gantry 
templates. Gantry::Init->base_root();

=head1 METHODS

=over 4

=item do_static

this method serves a static file from disk.

=back

=head1 SEE ALSO

    Gantry
    Gantry::Plugins

=head1 AUTHOR

Timotheus Keefer <tkeefer@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Timotheus Keefer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
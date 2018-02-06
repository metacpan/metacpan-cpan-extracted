package Hazy;

use strict;
use warnings;
use 5.012;
use Cwd qw/abs_path/;
our $VERSION = '0.04';

sub new {
    my ( $pkg, @new ) = @_;
    my %args = scalar @new == 1 ? @{ shift @new } : @new;
    $args{file_name} //= 'test';
    $args{find}      //= 'css';
    my $path = abs_path( [caller()]->[1] );
    $args{abs_path} = substr($path, 0, rindex($path, '/'));
    if ($args{write_dir}) {
	$args{write_dir} = sprintf "%s/%s", $args{abs_path}, $args{write_dir};
	unless(-d $args{write_dir}) {
	    my $dir = '';
	    map {
		(-e ($dir .= "/$_")) or mkdir $dir;
	    } (split /\//, $args{write_dir});
        }
    }
    bless {%args}, $pkg;
}

sub process {
    $_[1] //= $_[0]->{read_dir} // die 'No read_dir provided';
    $_[1] = sprintf "%s/%s", $_[0]->{abs_path}, $_[1];
    my ( $spec, @files ) = $_[0]->lookup_dir( $_[1] );
    my $build_css;
    for my $css_file (@files) {
        open my $fh, "<$css_file" or die "Cannot open $css_file";
        my $css = do { local $/; <$fh> };
        $css = $_[0]->make_replacements( $spec, $css );
        $build_css .= $css;
    }
    my $write = exists $_[0]->{write_dir}
      ? sprintf "%s/%s", $_[0]->{write_dir}, $_[0]->{file_name}
      : $_[0]->{file_name};
    write_file( "$write.css",     $build_css );
    write_file( "$write.min.css", $_[0]->min_css($build_css) );
    return 1;
}

sub write_file {
    open( my $fh, '>', $_[0] ) or die "could not open file $_[0]";
    print $fh $_[1];
    close $fh;
}

sub make_replacements {
    my $regx = join "|", map { quotemeta($_) } keys %{ $_[1] };
    return $_[2] unless $regx;
    $_[2] =~ s/($regx)/$_[1]->{$1}/g;
    ( !$_[2] =~ m/\n$/ ) and $_[2] .= "\n";
    return $_[2];
}

sub lookup_dir {
    my $look = $_[0]->{find};
    opendir( my $dh, $_[1] ) or die "Could not open dir - $_[1]";
    my %files = map { $_ => sprintf "%s/%s", $_[1], $_ }
      grep { /config|\.$look$/ } readdir $dh;
    closedir($dh);
    my $spec = delete $files{config} or die 'no config found';
    return ( _read_spec($spec), sort values %files );
}

sub min_css {
    $_[1] =~ s/[\s]{2,}|[\t\r\n]+//g;
    my %minify = (' {', '{', '{ ', '{', ' }', '}', '} ', '}', ': ', 
	':', ';}', '}', ' ,', ',', ', ', ',', '( ', '(', ' )', ')' );
    my $regx = join "|", map { quotemeta($_) } sort keys %minify;
    $_[1] =~ s/($regx)/$minify{$1}/g;
    $_[1];
}

sub _read_spec {
    my ( %spec, %arg );
    open( my $fh, "<$_[0]" );
    $arg{end} = ';';
    while ( sysread( $fh, $arg{buffer}, 1 ) ) {
	if ( ! exists $arg{value} && $arg{buffer} =~ m/\s/ ) { next }	
	if ( !$arg{flag} && !$arg{multi} && $arg{buffer} eq ':' ) { $arg{flag} = 1; next; }
        if ($arg{buffer} eq $arg{end}) {
	    map { $arg{$_} =~ s/^\s+|\s+$// } qw/key value/;
	    $spec{"$arg{key}"} = $arg{value};
            map { delete $arg{$_} } qw/key value flag multi/;
	    $arg{end} = ';';
            next;
        }
	if ( exists $arg{flag} && ! exists $arg{value} ) {
		next if ($arg{buffer} =~ m/\s/);
		if ($arg{buffer} =~ m/[\@\$\^\&\*\{\/\\\~\`\>\<\+\_\]\[\?\|\"\'\=\!]/ ) {
			$arg{multi} = 1;
			$arg{end} = $arg{buffer};
			next;
		}
	}
        exists $arg{flag} ? ( $arg{value} .= $arg{buffer} ) : ( $arg{key} .= $arg{buffer} );
    }
    close($fh);
    return \%spec;
}

1;

__END__


=head1 NAME

Hazy - A simple, minimalistic CSS framework.

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS
    
    *
    **
    # hazy.pl
    use Hazy;

    Hazy->new(
        read_dir => 't/vanilla/', 
        write_dir => 'static/css', 
        file_name => 'vanilla', 
        find => 'high', # default is css
    )->process();

    1;

    ***

    # Create a config 
    # t/hazy/config ....
    @one: #fff;
    $two: #ccc;
    %three: auto 0;
    *four: * 
	padding: 10px; 
	margin: auto;
    * 

    ****

    # Add some *css* files - t/hazy/base.meh
    body {
        background: @one;
        color: $two;
	*four
    }
    # form.css
    .form {
        margin: %three;
    }

    *****

    # run

    perl hazy.pl

    ******

    # compiles static/css/shiny.min.css or static/css/shiny.css
    .body{background:#fff;color:#ccc}.div{margin:auto,0}

 
=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-least at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hazy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hazy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hazy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hazy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hazy>

=item * Search CPAN

L<http://search.cpan.org/dist/Hazy/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2017 LNATION.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

 # End of Hazy

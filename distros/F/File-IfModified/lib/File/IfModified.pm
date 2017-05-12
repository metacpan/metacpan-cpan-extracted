package File::IfModified;
use 5.008001;
use strict;
use Exporter 'import';
our @EXPORT_OK = qw(if_modified touch vtouch vtouch_all);
our $VERSION = qw(0.20);

my %mtime;
sub if_modified{
    my $file = shift;
    my $mtime = (stat $file)[9];
    if ( defined $mtime ){
        if ( exists $mtime{$file} ){
            return if ( $mtime{$file} eq $mtime );
        }
        $mtime{ $file } = $mtime;
        return 1;
    }
    else {
        delete $mtime{$file};
        return 1;
    }
}
sub touch{
    my $file = shift;
    open my $fh, "+>", $file or die "touch: $file";
    close $fh;
    delete $mtime{$file};
}

sub vtouch{
    delete $mtime{$_[0]};
}
sub vtouch_all{
    %mtime = ();
}
1;
__END__
=head1 NAME

File::IfModified - Perl extension for checking if-modified state of file

=head1 SYNOPSIS

  use File::IfModified qw(if_modified);

  my $cached_data;
  my $file = 'data for initialization of $cached_data';
  while( 1 ){
    if ( if_modified( $file ){
      
        # Open $file and
        # Init $cached_data
        ...
    } 
    # Use $cached_data
    ... 
    sleep 1;
  }

=head1 DESCRIPTION

  This module usefull for long running script with external dependenses on other files

=head2 EXPORT

None by default.

=head2 EXPORT_OK
=cut

=over 

=item if_modified( $file )
    --- return status of $file for current script 

=item touch( $file )
    --- perl equivalent of unix touch

=item vtouch( $file ) 
    --- virtual equivalent of touch: Flush internal cache "if_modified" for current file

=item vtouch_all( $file )
    --- flush all "if_modified" cache.


=head1 SEE ALSO

    L<File-Modified>.

=head1 AUTHOR

A. G. Grishaev, E<lt>grian@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by A. G. Grishaev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

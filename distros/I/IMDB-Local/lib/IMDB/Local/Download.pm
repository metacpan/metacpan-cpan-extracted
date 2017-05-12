package IMDB::Local::Download;

use 5.006;
use strict;
use warnings;

=head1 NAME

IMDB::Local::Download - Object to manage IMDB List file downloads.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    my $foo = new IMDB::Local::Download('listsDir' => "./imdb-data/lists");

    my $forceRefresh=1;

    $foo->download($forceRefresh);
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=cut

use LWP;

# Use Term::ProgressBar if installed.
use constant Have_bar => eval {
    require Term::ProgressBar;
    $Term::ProgressBar::VERSION >= 2;
};


use IMDB::Local::ListFiles;

=head2 new

=cut

use Class::MethodMaker
    [ 
      scalar => ['listsDir'],
      scalar => [{-default => 0}, 'verbose'],
      scalar => [{-default => 'ftp://ftp.fu-berlin.de/pub/misc/movies/database'}, 'baseUrl'],
      scalar => [{-default => 1}, 'movies'],
      scalar => [{-default => 1}, 'directors'],
      scalar => [{-default => 1}, 'actors'],
      scalar => [{-default => 1}, 'actresses'],
      scalar => [{-default => 1}, 'genres'],
      scalar => [{-default => 1}, 'ratings'],
      scalar => [{-default => 1}, 'keywords'],
      scalar => [{-default => 1}, 'plot'],
      scalar => [{-default => 1}, 'showProgressBar'],

      scalar => [{ -type => 'IMDB::Local::ListFiles'}, '_listFiles'],
      new  => [qw/ -init -hash new /] ,
    ];

=head2 movies(boolean)

specify if movies list file should be included in list of files to download

=head2 directors(boolean)

specify if directors list file should be included in list of files to download

=head2 actors(boolean)

specify if actors list file should be included in list of files to download

=head2 actresses(boolean)

specify if actresses list file should be included in list of files to download

=head2 genres(boolean)

specify if genres list file should be included in list of files to download

=head2 ratings(boolean)

specify if ratings list file should be included in list of files to download

=head2 keywords(boolean)

specify if keywords list file should be included in list of files to download

=head2 plot(boolean)

specify if plot list file should be included in list of files to download

=cut

sub init
{
    my ($self)=@_;

    $self->_listFiles(new IMDB::Local::ListFiles(listsDir=>$self->listsDir(),
						 movies=>$self->movies(),
						 directors=>$self->directors(),
						 actors=>$self->actors(),
						 actresses=>$self->actresses(),
						 genres=>$self->genres(),
						 ratings=>$self->ratings(),
						 keywords=>$self->keywords(),
						 plot=>$self->plot()));


    if ( ! -d $self->listsDir() ) {
	die $self->listsDir().":does not exist";
    }

    # only leave progress bar on if its available
    if ( !Have_bar ) {
	$self->showProgressBar(0);
    }

    return($self);
}

=head2 listFiles

Get an array of list files

=cut

sub listFiles($)
{
    my ($self)=@_;

    return $self->_listFiles->listFiles();
}


=head2 downloadListFile

Same as download() but when you want to control each list file.
If an existing list file exists it is removed prior to download starting.

=cut

sub downloadListFile($$$)
{
    my ($self, $type, $force)=@_;

    my $filepath=$self->_listFiles->paths_index($type);
    if ( $force && -f $filepath ) {
	unlink($filepath);
    }

    $self->_listFiles()->statFiles();

    my $url = $self->baseUrl()."/$type.list.gz";
    
    #my $filepath = $self->listsDir()."/$type.gz";
    
    #warn "$filepath: does not exist\n";
    
    my $partial = $self->listsDir()."/$type.gz.partial";
    if (-e $partial) {
	unlink $partial or die "cannot unlink $partial: $!";
    }
    
    print "Downloading $url..\n";

    #
    # For downloading we use LWP
    #
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy();
    $ua->show_progress(($self->showProgressBar()!=0));
    
    my $req = HTTP::Request->new(GET => $url);
    $req->authorization_basic('anonymous', 'IMDB::Local::Download');
    
    my $resp = $ua->request($req, $filepath);
    my $got_size = -s $filepath;
    
    if (defined $resp and $resp->is_success ) {
	die if not $got_size;
	print "<$url>\n\t-> $filepath, success\n\n";
    }
    else {
	my $msg = "failed to download $url to $filepath";
	$msg .= ", http response code: ".$resp->status_line if defined $resp;
	warn $msg;
	if ($got_size) {
	    warn "renaming $filepath -> $partial\n";
	    rename $filepath, $partial
		or die "cannot rename $filepath to $partial: $!";
	    warn "You might try continuing the download of <$url> manually.\n";
	}
	return(0);
    }
    return(1);
}

=head2 download

Attempt to download all missing list files

=cut

sub download
{
    my ($self, $force)=@_;
    
    $self->_listFiles()->statFiles();

    for my $type ( $self->_listFiles->listFiles() ) {
	
	# skip the ones that are already downloaded
	my $filepath=$self->_listFiles->paths_index($type);
	if ( -f $filepath && ! $force ) {
	    next;
	}

	if ( $self->downloadListFile($type, $force) != 1 ) {
	    # stop short
	    return(0);
	}
    }

    return(1);
}


=head1 AUTHOR

jerryv, C<< <jerry.veldhuis at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-imdb-local at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IMD-Local>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IMDB::Local::Download


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IMDB-Local>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IMDB-Local>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IMDB-Local>

=item * Search CPAN

L<http://search.cpan.org/dist/IMDB-Local/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 jerryv.

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

1; # End of IMDB::Local::Download

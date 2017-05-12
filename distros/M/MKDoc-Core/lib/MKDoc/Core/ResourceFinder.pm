=head1 NAME

MKDoc::Core::ResourceFinder - Inheritable resources module.


=head1 SUMMARY

There's more to a web application than just code. Typically you also want to
have also config files, some images (i.e logos, buttons, etc), some CSS files,
some templates, etc.

Those things need to have a URI and they also need to be accessible from within
your program.

Ideally you want to be able to:

=over 4

=item Bundle those files with your CPAN distribution.

=item Serve those files 'out of the box' when installing a new site.

=item Have an easy mechanism to override those files.

=back

L<MKDoc::Core::ResourceFinder> is a module providing helper functions in order
to achieve this goal.

Any L<MKDoc::Core> product can bundle resource files anywhere in
lib/MKDoc/resources.  It means that the files will be installed somewhere in
@INC/MKDoc/resources.

The L<MKDoc::Core::Plugin::Resources> will serve the files so that a request to
/.resources/foo/bar.txt serves the right @INC/MKDoc/resources/foo/bar.txt file.

However, those files are mainly 'factory default', shipped so that you can have
something working immediately.  You certainly almost always want to redefine
them either on a server-wide basis, or even on a per-site basis. 

In order to accomplish this, the L<MKDoc::Core::ResourceFinder> looks for
resources in:

=over 4

=item <SITE_DIR>/resources 

=item <MKDOC_DIR>/resources

=item @INC/resources

=back

Furthermore, whenever it sees a file which is called "<filename>.deleted" it
will consider that the file is not there, even if it's defined later on.

=cut
package MKDoc::Core::ResourceFinder;
use warnings;
use strict;

our $DIRS = undef;


sub permanent_resource_dirs
{
    $DIRS and return @{$DIRS};

    my $MKDOC_DIR = $ENV{MKDOC_DIR} || '.';   

    my @dirs = @INC; 
    my @res = ();
    push @res, $MKDOC_DIR . '/resources';
    push @res, map { $_ ? "$_/MKDoc/resources" : () } grep ( !/^\Q$MKDOC_DIR\E$/, @INC );

    my @new_res = ();
    my %seen    = ();
    foreach my $res (@res)
    {
        $seen{$res} and next;
        $seen{$res} = 1;
        -d $res or next;
        push @new_res, $res;
    }

    $DIRS = \@new_res;
    
    return @{$DIRS};
}


=head1 API

=head2 MKDoc::Core::ResourceFinder::list ($some_directory);

Reads the content of multiple directories (<SITE_DIR>/resources,
<MKDOC_DIR>/resources, @INC) and merges it in a single list.  Returns the
merged list.

Use this instead of readdir().

=cut
sub list
{
    my $dir   = shift;
    my %files = ();
    my %nono  = ();

    foreach my $base ("$ENV{SITE_DIR}/resources", permanent_resource_dirs())
    {
        -d $base || next;
        my $dir_path = $base . $dir;

        opendir DD, $dir_path or next;
        my @files = readdir (DD);
        closedir (DD);

        %nono  = ( (%nono), ( map { s/\.deleted$//; $_ } grep /\.deleted$/, @files ) );
        @files = grep !/\.deleted$/, @files;
         
        for (@files)
        {
            $_ || next;
            $nono{$_} && next;
            $files{$_} = 1;
        }
        closedir DD;
    }
   
    my @res = sort keys %files;
    return wantarray ? @res : \@res;
}


=head2 MKDoc::Core::ResourceFinder::rel2abs ($something);

Searches for $something in multiple directories, and returns the full path if found.
Returns undef otherwise.

=cut
sub rel2abs
{
    my $rel = shift;
    $rel =~ s/^\///;

    foreach my $dir ("$ENV{SITE_DIR}/resources", permanent_resource_dirs())
    {
        $dir || next;
        my $file = "$dir/$rel";
        -f "$file.deleted" and return;
        -f $file and return $file;
    }

    return;
}


1;


__END__

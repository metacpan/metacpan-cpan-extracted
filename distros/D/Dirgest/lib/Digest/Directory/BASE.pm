
######################################################################
#
#   Directory Digest -- Digest::Directory::BASE.pm 
#   Matthew Gream (MGREAM) <matthew.gream@pobox.com>
#   Copyright 2002 Matthew Gream. All Rights Reserved.
#   $Id: BASE.pm,v 0.90 2002/10/21 20:24:06 matt Exp matt $
#    
######################################################################

=head1 NAME

Digest::Directory::BASE - base class for Directory Digests

=head1 SYNOPSIS

  use Digest::Directory::BASE;
  
  my($d) = Digest::Directory::BASE->new;
  
  $d->quiet(1);
  $d->include("/etc");
  $d->include("/usr");
  $d->exclude("/usr/local");
  $d->compute();
  $d->save("/var/dirgests/root.dirgests");

=head1 REQUIRES

Perl 5.004, Digest::MD5, File::Find, LWP::UserAgent.

=head1 EXPORTS

Nothing.

=head1 DESCRIPTION

B<Digest::Directory::BASE> is a base class for creating digests of 
file and directory sets. Clients can specify include and exclude 
file and directory specifications, and then compute digests over 
these sets, with optional prefix trimming. Clients can also fetch, 
load, save, print, compare or export these sets.

=cut

######################################################################

package Digest::Directory::BASE;

require 5.004;

use strict;
use warnings;
use vars qw( @ISA $PROGRAM $VERSION $AUTHOR $RIGHTS $USAGE );
@ISA = qw(Exporter);

$PROGRAM = "Digest::Directory::BASE";
$VERSION = sprintf("%d.%02d", q$Revision: 0.90 $ =~ /(\d+)\.(\d+)/);
$AUTHOR = "Matthew Gream <matthew.gream\@pobox.com>";
$RIGHTS = "Copyright 2002 Matthew Gream. All Rights Reserved.";
$USAGE = "see pod documentation";

######################################################################

use Digest::MD5;
use File::Find;
use Fcntl ':mode';
use LWP::UserAgent;

######################################################################

=head1 METHODS

The following methods are provided:

=over 4

=cut


######################################################################

=item B<$dirgest = Digest::Directory::BASE-E<gt>new( )>

Create a dirgest instance; sets up default options, no quiet,
no includes, no excludes, zero digest and zero summary.

=cut

######################################################################

sub new
 {
    my($class) = @_;

    my $self = {
        quiet => 0,
        trim => 0,
        include => {},
        exclude => {},
        digests => {},
        summary => ""
    };

    return bless $self, $class;
 }


######################################################################

=item B<$dirgest-E<gt>quiet( $enabled )>

Enable quiet operating mode for a dirgest; ensures that no debug
trace output is provided during operation.

$enabled => '0' or '1' for whether operation to be quiet or not;

=cut

######################################################################

sub quiet
 {
    my($self, $q) = @_;

    $self->{'quiet'} = $q;
    return 1;
 }


######################################################################

=item B<$dirgest-E<gt>trim( $count )>

Enable trimming of file/directory names;

$count => 'n' where 'n' > 0 && 'n' specifies number of leading
elements to trim, e.g. '/a/b/c' trim 2 == 'b/c';

=cut

######################################################################

sub trim
 {
    my($self, $t) = @_;

    ( $t >= 0 ) || return 0;
    $self->{'trim'} = $t;
    return 1;
 }


######################################################################

=item B<$result = $dirgest-E<gt>configure( $file )>

Read a configuration file into a dirgest;

$file => filename to read configuration from;

return => '1' on success, or '0' on failure;

File should contain lines with '+name' or '-name' that are turned 
into include or exclude file/directory sets. All other names are 
ignored. Whitespace may be present: ' + name', ' +name', '+ name',
etc. Also, '!trim=n' will set trim level, and '!quiet=n' will set
quiet level.

=cut

######################################################################

sub configure
 {
    my($self, $file) = @_;

    print "configuring from $file\n" 
        if (!$self->{'quiet'});

    if (open(FILE, "<$file"))
    {
        while (<FILE>)
        {
            if (/^[ \t]*\-[ \t]*(.*)[ \t]*$/)
            {    
                $self->exclude($1);
            }
            elsif (/^[ \t]*\+[ \t]*(.*)[ \t]*$/)
            {
                $self->include($1);
            }
            elsif (/^[ \t]*\![ \t]*trim[ \t]*=[ \t]*([\d]+)/i)
            {
                $self->trim($1);
            }
            elsif (/^[ \t]*\![ \t]*quiet[ \t]*=[ \t]*([\d]+)/i)
            {
                $self->quiet($1);
            }
        }

        close(FILE);

        return 1;
    }
    else
    {
        return 0;
    }
 }


######################################################################

=item B<$dirgest-E<gt>include( $name )>

Include a name in the compute set for a dirgest;

$name => particular name of file/directory set to include into
compute operation.

=cut

######################################################################

sub include
 {
    my($self, $name) = @_;

    print "including ", $name, "\n"
        if (!$self->{'quiet'});

    $self->{'include'}{$name} = 1;
    return 1;
 }


######################################################################

=item B<$dirgest-E<gt>exclude( $name )>

Exclude a name from the compute set for a dirgest;

$name => particular name of file/directory set to exclude from
compute operation.

=cut

######################################################################

sub exclude
 {
    my($self, $name) = @_;

    print "excluding ", $name, "\n"
        if (!$self->{'quiet'});

    $self->{'exclude'}{$name} = 1;
    return 1;
 }

sub digests
 {
    my($self) = @_;

    return %{$self->{'digests'}};
 }
sub summary
 {
    my($self) = @_;

    return $self->{'summary'};
 }


######################################################################

=item B<%stats = $dirgest-E<gt>statistics( )>

Return a hash with statistics about the dirgest; the hash 
contains the following elements:

'include' => number of includes specified;

'exclude' => number of excludes specified;

'digests' => number of digests;

'quiet' => quiet enable or not;

'trim' => trim level in operation;

return => the hash;
    
=cut

######################################################################

sub statistics
 {
    my($self) = @_;

    my(%stats);
    $stats{'include'} = scalar( keys %{$self->{'include'}} );
    $stats{'exclude'} = scalar( keys %{$self->{'exclude'}} );
    $stats{'digests'} = scalar( keys %{$self->{'digests'}} );
    $stats{'quiet'} = $self->{'quiet'};
    $stats{'trim'} = $self->{'trim'};

    return %stats;
 }


######################################################################

=item B<$dirgest-E<gt>clear( )>

Clear a dirgest;

'clear' out all of the dirgests, and reset the summary.

=cut

######################################################################

sub clear
 {
    my($self) = @_;

    $self->{'digests'} = {};
    $self->{'summary'} = "";
 }

sub parse
 {
    my($self, $l) = @_;

    $_ = $l;
    my($t) = $self->{'trim'};
    if (/^= ([^=]*==[ ]*[\d]*)[ ]*([^\r\n]*).*$/)
    {
        my $d = $1;
        my $f = $2; $f =~ s|^([^/]*/){$t}||;
        $self->{'digests'}{$f} = $d;
    }
    elsif (/^# ([^=]*==).*$/)
    {
        my $s = $1;
        $self->{'summary'} = $s;
    }
 }


######################################################################

=item B<$result = $dirgest-E<gt>fetch( $link, $user, $pass )>

Fetch dirgests from a url;

$link => the link to fetch from, should have protocol specifier, e.g.
'http://matthewgream.net', 'file://source.dirgest.org';

$user => the http username for basic authorisation (if desired);

$pass => the http password for basic authorisation (if desired);

return => '1' on success, or '0' on failure;

=cut

######################################################################

sub fetch 
 {
    my($self, $url, $user, $pass) = @_;

    print "fetching from $url\n"
        if (!$self->{'quiet'});

    my $ua = LWP::UserAgent->new;
    $ua->agent("Mozilla/5.5 compatible: Dirgest/$VERSION");

    $_ = $url; if (/^http/ig) { $url .= "\?o=show"; }
    my $req = HTTP::Request->new(GET => $url);
    if (defined $user && defined $pass)
    {
        $req->authorization_basic($user, $pass);
    }

    my $res = $ua->request($req);
    if ( $res->is_success() ) 
    {
        foreach (split(/\n/, $res->content))
        {
            $self->parse($_);
        }
    
        $self->summarise();

        return 1;
    }
    else
    {
        return 0;
    }
 }


######################################################################

=item B<$result = $dirgest-E<gt>load( $file )>

Load dirgests from a file;

$file => the name of the file to load from;

return => '1' on success, or '0' on failure;

=cut

######################################################################

sub load
 {
    my($self, $file) = @_;

    print "reading from $file\n"
        if (!$self->{'quiet'});

    if (open(FILE, "<$file"))
    {
        while (<FILE>)
        {
            $self->parse($_);
        }

        close(FILE);

        $self->summarise();

        return 1;
    }
    else
    {
        return 0;
    }
 }


######################################################################

=item B<$result = $dirgest-E<gt>save( $file )>

Save dirgests to a file;

$file => the name of the file to save to;

return => '1' on success, or '0' on failure;

=cut

######################################################################

sub save
 {
    my($self, $file) = @_;

    print "writing to $file\n"
        if (!$self->{'quiet'});

    if (open(FILE, ">$file"))
    {
        foreach my $f (sort(keys %{$self->{'digests'}}))
        {
            print FILE "= ", $self->{'digests'}{$f}, " ", $f, "\n";
        }
        
        $self->summarise();

        if (length($self->{'summary'}))
        {
            print FILE "# ", $self->{'summary'}, "\n";
        }

        close(FILE);

        return 1;
    }
    else
    {
        return 0;
    }
 }


######################################################################

=item B<$result = $dirgest-E<gt>compute( )>

Compute dirgests from given include/exclude sets;

return => 'n' where 'n' is the number of dirgests computed;

=cut

######################################################################

my(%digests_temp) = ();
my($digests_trim) = 0;
my(%digests_excl) = ();
sub compute
  {
    my($self) = @_;
    my($result) = 0;

    %digests_temp = ();
    $digests_trim = $self->{'trim'};
    %digests_excl = %{$self->{'exclude'}};

    foreach my $d (keys %{$self->{'include'}})
    {
        print "computing from $d\n" 
            if (!$self->{'quiet'});

        find( { wanted => \&compute_impl, follow => 1, no_chdir => 1 }, $d);
        ++$result;
    }

    %{$self->{'digests'}} = %digests_temp;
    %digests_temp = ();
    %digests_excl = ();
    $digests_trim = 0;

    $self->summarise();

    return $result;
  }
sub compute_impl
  { 
    my $file = $File::Find::name;
    my @stat = (stat($file));
    
    if (!@stat)
    {
        $file =~ s|^([^/]*/){$digests_trim}||;
        $digests_temp{$file} = "======================== ============";
        return;
    }

    my $exclude = 0;
    foreach my $e (keys %digests_excl) 
    {
        if (!$exclude && $file =~ /$e/)
        {
            $exclude = 1;
        }        
    }

    if (!$exclude)
    {
        my $mode = (@stat)[2];
        my $size = (@stat)[7];
        if (! S_ISDIR($mode) )
        {
            if (open (FILE, $file)) 
            {
                binmode(FILE);
                my $digest = Digest::MD5->new;
                $digest->addfile(*FILE);
                close(FILE);

                $file =~ s|^([^/]*/){$digests_trim}||;
                $digests_temp{$file} = 
                    $digest->b64digest .  "== " . sprintf("%012d", $size);
            }
            else
            {
                $file =~ s|^([^/]*/){$digests_trim}||;
                $digests_temp{$file} = 
                    "======================== ============";
            }
        }
    }
  }


######################################################################

=item B<$result = $dirgest-E<gt>print( $nodetails, $nosummary )>

Print a dirgest;

$nodetails => don't print detailed dirgests;

$nosummary => don't print summary dirgests;

return => 'n' where 'n' is the number of dirgests printed;

=cut

######################################################################

sub print
  {
    my($self, $nodetails, $nosummary) = @_;
    my($result, $string) = $self->results_impl($nodetails, $nosummary);
    print $string if ($string);
    return $result;
  }


######################################################################

=item B<$string = $dirgest-E<gt>string( $nodetails, $nosummary )>

Export a dirgest;

$nodetails => don't stringify detailed dirgests;

$nosummary => don't stringify summary dirgests;

return => 'n' where 'n' is the number of dirgests printed;

=cut

######################################################################

sub string
  {
    my($self, $nodetails, $nosummary) = @_;
    my($result, $string) = $self->results_impl($nodetails, $nosummary);
    return $string;
  }

sub results_impl
  {
    my($self, $nodetails, $nosummary) = @_;

    $nodetails = 0 if (not defined $nodetails);
    $nosummary = 0 if (not defined $nosummary);

    my($result) = 0;
    my($string) = "";

    if (!$nodetails)
    {
        foreach my $f (sort(keys %{$self->{'digests'}}))
        {
            $string .= "= "; 
            $string .= $self->{'digests'}{$f};
            $string .= " ";
            $string .= $f;
            $string .= "\n";
            ++$result;
        }
    }
    if (!$nosummary)
    {
        $self->summarise();

        if (length($self->{'summary'}))
        {
            $string .= "# ";
            $string .= $self->{'summary'};
            $string .= "\n";
        }
    }
    return ($result, $string);
  }

sub summarise
  {
    my($self) = @_;

    if (!length($self->{'summary'}) && scalar(keys %{$self->{'digests'}}))
    {
        $self->{'summary'} = $self->summarise_impl( \%{$self->{'digests'}} );
    }
  }

sub summarise_impl
  {
    my($self, $digests) = @_;

    my($digest) = Digest::MD5->new;

    foreach my $f (sort(keys %$digests))
    {
        $digest->add( join('', $$digests{$f}, " ", $f) );
    }

    return join ('', $digest->b64digest, "==");
  }


######################################################################

=item B<$result = $dirgest-E<gt>compare( $peer, $nodetails, $nosummary, $showequals )>

Compare dirgest with another with options;

$peer => the peer dirgest;

$nodetails => don't compare detailed dirgests;

$nosummary => don't compare summary dirgests;

$showequals => show equal dirgests during activity;

return => 'n' where 'n' is the number of differences found;

=cut

######################################################################

sub compare
  {
    my($self, $peer, $nodetails, $nosummary, $showequal) = @_;
    my($result) = 0;

    $nodetails = 0 if (not defined $nodetails);
    $nosummary = 0 if (not defined $nosummary);
    $showequal = 0 if (not defined $showequal);

    if (!$nodetails)
    {
      print "comparing digests\n" 
          if (!$self->{'quiet'});

      my(%digests_l) = $peer->digests();
      foreach my $f (sort(keys %{$self->{'digests'}}))
      {
        my ($c) = $self->{'digests'}{$f};
        
        if (!defined $digests_l{$f})
        {
            print "< ", $c, " ", $f, "\n";
            ++$result;
        } 
        else 
        {
            if ($c ne $digests_l{$f})
            {
                print "! ", $c, " ", $f, "\n";
                ++$result;
            }
            else
            {
                print "= ", $c, " ", $f, "\n"
                    if ($showequal);
            }
            delete $digests_l{$f}
        }
      }
      foreach my $f (sort(keys %digests_l))
      {
        my ($c) = $digests_l{$f};
        print "> ", $c, " ", $f, "\n";
        ++$result;
      }
    }

    if (!$nosummary)
    {
        print "comparing summaries\n" 
            if (!$self->{'quiet'});

        if ($peer->summary() ne $self->summary())
        {
            print "? ", $peer->summary(), "\n";
            ++$result;
        }
        elsif ($showequal)
        {
            print "# ", $peer->summary(), "\n";
        }
    }

    print "comparing differences: $result\n" 
        if (!$self->{'quiet'});

    return $result;
  }


######################################################################

=back

=head1 AUTHOR

Matthew Gream (MGREAM) <matthew.gream@pobox.com>

=head1 VERSION

Version 0.90

=head1 RIGHTS

Copyright 2002 Matthew Gream. All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

######################################################################

1;


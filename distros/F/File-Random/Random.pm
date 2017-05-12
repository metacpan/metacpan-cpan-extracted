package File::Random;

use 5.006;
use strict;
use warnings;

use File::Find;
use Carp;
use Want qw/howmany/;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 
  ':all' => [ qw(
	  random_file
	  content_of_random_file corf
      random_line
  ) ],
  # and for some backward compability
  'all' => [ qw(
	  random_file
   	  content_of_random_file corf
      random_line
  ) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{':all'} }, 'corf' );

our @EXPORT = qw(
	
);
our $VERSION = '0.17';

sub _standard_dir($);
sub _dir(%);

sub random_file {
	my @params = my ($dir, $check, $recursive) = _params_random_file(@_);
	
	return $recursive ? _random_file_recursive    (@params)
	                  : _random_file_non_recursive(@params);
}

*corf = *content_of_random_file;

sub content_of_random_file {
	my %args = @_;
	my $rf = random_file(%args) or return undef;
	my $dir = _standard_dir _dir %args;
	
	open RANDOM_FILE, "<", "$dir/$rf" 
		or die "Can't open the randomly selected file '$dir/$rf'";
	my @content = (<RANDOM_FILE>);
	close RANDOM_FILE;
	return wantarray ? @content : join "", @content;
}

sub random_line {
    my ($fname, $nr_of_lines) = @_;
    defined $fname or die "Need a defined filename to read a random line";
    if (!defined($nr_of_lines) and wantarray) {
        $nr_of_lines = howmany() || 1;
    }
    unless (!defined($nr_of_lines) or $nr_of_lines =~ /^\d+$/) {
        die "Number of random_lines should be a number, not '$nr_of_lines'";
    }
    defined($nr_of_lines) and $nr_of_lines == 0 and 
        carp "doesn't make a lot of sense to return 0 random lines, " .
             "you called me with random_line($fname,$nr_of_lines)";
    $nr_of_lines ||= 1;
    my @line  = ();
    open FILE, '<', $fname or die "Can't open '$fname' to read random_line";        
    if ($nr_of_lines == 1) {
        # Algorithm from Cookbook, chapter 8.6
        rand($.) < 1 && ($line[0] = $_) while (<FILE>);
    } else {
        wantarray or
            carp "random_line($fname,$nr_of_lines) was called in scalar context, ".
                 "what doesn't make a lot sense";
        while (<FILE>) {
            for my $lnr (0 .. $nr_of_lines-1) {
                $line[$lnr] = $_ if rand($.) < 1;
            }
        }
    }
    close FILE;
    return wantarray ? @line : $line[0];
}

sub _random_file_non_recursive {
	my ($dir, $check) = @_;

	opendir DIR, $dir or die "Can't open directory '$dir'";
	my @files = grep {-f "$dir/$_" and _valid_file($check, $_)} (readdir DIR);
	closedir DIR;

	return undef unless @files;
	return $files[rand @files];
}

sub _random_file_recursive {
	my ($dir, $check) = @_;

	my $i = 1;
	my $fname;

	my $accept_routine = sub {
		return unless -f; 
		
		# Calculate filename with relative path
		my ($f) = $File::Find::name =~ m:^$dir[/\\]*(.*)$:;
		return unless _valid_file($check,$f);
		# Algorithm from Cookbook, chapter 8.6
		# similar to selecting a random line from a file
		if (rand($i++) < 1) {
			$fname = $f;
		}
	};
	find($accept_routine, $dir);

	return $fname;	
}

sub _valid_file {
	my ($check, $name) = @_; 
	for (ref($check)) {
		    /Regexp/ && return $name =~ /$check/
		or  /CODE/   && ($_ = $name, return $check->($name));
	}
}

sub _dir (%) {
    my %args = @_;
    return $args{-d} || $args{-dir} || $args{-directory};
}

sub _params_random_file {
	my %args  = @_;
	
	for (qw/-d -dir -directory -c -check/) {
		exists $args{$_} and ! $args{$_} and 
		die "Parameter $_ is declared with a false value";
	}
    
    foreach (keys %args) {
        /^\-(d|dir|directory|
             c|check|
             r|rec|recursive)$/x or carp "Unknown option '$_'";
    }
    
	my $dir   = _standard_dir _dir %args;    
	my $check = $args{-c} || $args{-check} || sub {"always O.K."};
	my $recursive = $args{-r} || $args{-rec} || $args{-recursive};

	unless (!defined($check) or (scalar ref($check) =~ /^(Regexp|CODE)$/)) {
		die "-check Parameter has to be either a Regexp or a sub routine,".
		    "not a '" . ref($check) . "'";
	}
		
	return ($dir, $check, $recursive);
}

sub _standard_dir($) {    
	my $dir = shift() || '.';
	$dir =~ s:[/\\]+$::;
	return $dir;
}

1;
__END__

=head1 NAME

File::Random - Perl module for random selecting of a file

=head1 SYNOPSIS

  use File::Random qw/:all/;
 
  my $fname  = random_file();

  my $fname2 = random_file(-dir => $dir);
  
  my $random_gif = random_file(-dir       => $dir,
                               -check     => qr/\.gif$/,
							   -recursive => 1);
							   
  my $no_exe     = random_file(-dir   => $dir,
                               -check => sub {! -x});
							   
  my @jokes_of_the_day = content_of_random_file(-dir => '/usr/lib/jokes');
  my $joke_of_the_day  = content_of_random_file(-dir => '/usr/lib/jokes');
  # or the shorter
  my $joke = corf(-dir => '/usr/lib/jokes');
  
  my $word_of_the_day = random_line('/usr/share/dict/words');
  my @three_words     = random_line('/usr/share/dict/words',3);
  # or
  my ($title,$speech,$conclusion) = random_line('/usr/share/dict/words');

=head1 DESCRIPTION

This module simplifies the routine job of selecting a random file.
(As you can find at CGI scripts).

It's done, because it's boring (and errorprone), always to write something like

  my @files = (<*.*>);
  my $randf = $files[rand @files];
  
or 

  opendir DIR, " ... " or die " ... ";
  my @files = grep {-f ...} (readdir DIR);
  closedir DIR;
  my $randf = $files[rand @files];
 
It also becomes very boring and very dangerous to write 
randomly selection for subdirectory searching with special check-routines.

The simple standard job of selecting a random line from a file is implemented, too.
  
=head1 FUNCTION

=head2 random_file

=item random_file

Returns a randomly selected file(name) from the specified directory
If the directory is empty, undef is returned. There are 3 options:

  my $file = random_file(
     -dir         => $dir, 
	 -check       => qr/.../, # or sub { .... }
	 -recursive   => 1        # or 0
  );
  
Let's have a look to the options:

=over

=item -dir (-d or -directory)

Specifies the directory where file has to come from.

If no C<-dir> option is specified,
a random file from the current directory will be used.
That means '.' is the default for the C<-dir> option.

=item -check (-c)

With the C<-check> option you can either define
a regex every filename has to follow,
or a sub routine which gets the filename as argument.
The filename passed as argument includes the relative path 
(relative to the C<-dir> directory or the current directory).
The argument is passed implicit as localized value of C<$_> and
it is also the first parameter on the argument array C<$_[0]>.

Note, that C<-check> doesn't accept anything else
than a regexp or a subroutine.
A string like '/.../' won't work.

The default is no checking (undef).

=item -recursive (-r or -rec)

Enables, that subdirectories are scanned for files, too.
Every file, independent from its position in the file tree,
has the same chance to be choosen.
Now the relative path from the given subdirectory or the current directory
of the randomly choosen file is included to the file name.

Every true value sets recursive behaviour on,
every false value switches off.
The default if false (undef).

Note, that I programmed the recursive routine very defendly
(using C<File::Find>).
So switching -recursive on, slowers the program a bit :-)
Please look to the C<File::Find> module for any details and bugs
related to recursive searching of files.

=item unknown options

Gives a warning.
Unknown options are ignored.
Note, that upper/lower case makes a difference.
(Maybe, once a day I'll change it)

=back

=head2 FUNCTION content_of_random_file  (or corf)

Returns the content of a randomly selected random file.
In list context it returns an array of the lines of the selected file,
in scalar context it returns a multiline string with whole the file.
The lines aren't chomped.

This function has the same parameters and a similar behaviour to the
C<random_file> method. 
Note, that C<-check> option still gets passed the filename and 
not the file content.

Instead of the long C<content_of_random_file>,
you can also use the alias C<corf>
(but don't forget to say either C<use File::Random qw/:all/> or
C<use File::Random qw/corf/>)

=head2 FUNCTION random_line($filename [, $nr_of_lines])

Returns one or C<$nr_of_lines> random_lines from an (existing) file.

If the file is empty, undef is returned.

The algorithm used for returning one line is the one from the FAQ.
See C<perldoc -q "random line"> for details.
For more than one line (C<$nr_of_lines E<gt> 1>), 
I use nearly the same algorithm.
Especially the returned lines aren't a sample,
as a line could be returned doubled.

The result of C<random_line($filename, $nr)> should be quite similar to
C<map {random_line($filename)} (1 .. $nr)>, only the last way is not so efficient,
as the file would be read C<$nr> times instead of one times.

It also works on large files,
as the algorithm only needs two lines of the file
at the same time in memory.

C<$nr_of_lines> is an optional argument which is 1 at default.
Calling C<random_line> in scalar context with C<$nr_of_lines> greater than 1,
gives a warning, as it doesn't make a lot of sense.
I also gives you a warning of C<$nr_of_lines> is zero.

You also can write something like

  my ($line1, $line2, $line3) = random_line($fname);
  
and random_line will return a list of 3 randomly choosen lines.
Allthough C<File::Random> tries its best to find out how many lines
you wanted, it's not an oracle, so

  my @line = random_line($fname);
  
will be interpreted as

  my @line = random_line($fname,1);

=head2 EXPORT

None by default.

You can export the function random_file with
C<use File::Random qw/random_file/;>,
C<use File::Random qw/content_of_random_file/> or with the more simple
C<use File::Random qw/:all/;>.

I didn't want to pollute namespaces as I could imagine,
users write methods random_file to create a file with random content.
If you think I'm paranoid, please tell me,
then I'll take it into the export.

=head1 DEPENDENCIES

This module requires these other modules and libraries:

  Want
  
For the tests are also needed many more modules:

  Test::More
  Test::Exception
  Test::Class
  Set::Scalar
  File::Temp
  Test::Warn
  Test::ManyParams
  
Test::Class itselfs needs the following additional modules:
  Attribute::Handlers             
  Class::ISA                      
  IO::File                        
  Storable
  Test::Builder
  Test::Builder::Tester
  Test::Differences    

All these modules are needed only for the tests.
You can work with the module even without them. 
These modules are only needed for my test routines,
not by the File::Random itself.
(However, it's a good idea most to install most of the modules anyway).


=head1 TODO

A C<-firstline> or C<-lines => [1 .. 10]> option for the
C<content_of_random_file> could be useful. 

Also speed could be improved,
as I tried to write the code very readable,
but wasted sometimes a little bit speed.

Please feel free to suggest me anything what could be useful.

=head1 BUGS

Well, because as this module handles some random data, 
it's a bit harder to test.
So a test could be wrong, allthough everything is O.K..
To avoid it, I let many tests run,
so that the chances for misproofing should be < 0.0000000001% or so.
Even it has the disadvantage that the tests need really long :-(

I'm not definitly sure whether my test routines runs on OS,
with path seperators different of '/', like in Win with '\\'.
Perhaps anybody can try it and tell me the result.
[But remember Win* is definitly the greater bug.]

=head1 COPYRIGHT

This Program is free software.
You can change or redistribute it under the same condition as Perl itself.

Copyright (c) 2002, Janek Schleicher, E<lt>bigj@kamelfreund.deE<gt>

=head1 AUTHOR

Janek Schleicher, E<lt>bigj@kamelfreund.deE<gt>

=head1 SEE ALSO

L<Tie::Pick> 
L<Data::Random>
L<Algorithm::Numerical::Sample>

=cut

#! /usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Log::Dispatch::Scribe;
use Pod::Usage;

my @cat_re;
my %args = (
    host => 'localhost',
    port => 1463,
    level => 'info',
    'retry-plan-a' => 'buffer',
    'retry-plan-b' => 'discard',
    'retry-buffer-size' => 100000,
    'retry-count' => 100,
    'retry-delay' => 10,
    'category-re' => sub { my ($name, $key, $value) = @_; push(@cat_re, [ $key, $value ]); },
);

GetOptions(\%args,
	   'category=s',
	   'category-re=s%',
	   'port=i',
	   'host=s',
	   'level=s',
	   'retry-plan-a=s',
	   'retry-plan-b=s',
	   'retry-buffer-size=i',
	   'retry-count=i',
	   'retry-delay=i',
	   'debug:s',
	   "help|?",
    ) or pod2usage(-exitval => 2, -verbose => 0);

pod2usage(-exitval => 0, -verbose => 2) if $args{'help'};

my $dbg_file;
my $debug;
if (defined $args{debug}) {
    $debug++;
    if ($args{debug}) {
	open($dbg_file, '>', $args{debug}) or die "Failed to open debug file $args{debug}: $!";
    }
    else {
	$dbg_file = \*STDERR;
    }
    select($dbg_file);
    $| = 1;
}

my $log = Log::Dispatch::Scribe->new(
    name       => 'scribe',
    min_level  => $args{level},
    host       => $args{host},
    port       => $args{port},
    default_category => $args{category},
    retry_plan_a => $args{'retry-plan-a'},
    retry_plan_b => $args{'retry-plan-b'},
    retry_buffer_size => $args{'retry-buffer-size'},
    retry_count => $args{'retry-count'},
    retry_delay => $args{'retry-delay'},
    );


my $extract_cat;
if (@cat_re > 0) {
    # compile a sub to evaluate the regexp matches and substitutions
    my $s = q&
$extract_cat = sub {
   my $line = shift;
&;
    for (@cat_re) {
	my ($sub, $val) = @$_;
	$val =~ s/([{}#])/\\$1/g; # escape meaningful characters
	$s .= qq&
   if (\$line =~ m{$val} ) {
     my \$ret = "$sub";
     chomp \$ret;
     return \$ret;
   }
&;
    }
    $s .= q&
   return;
}
&;
    print $dbg_file $s if $debug;
    eval $s;
}

while (my $line = <>) {
    my $cat;
    $cat = $extract_cat->($line) if defined $extract_cat;

    print $dbg_file ($cat || '') . ' ' . $line if $debug;
    $log->log( level => $args{level}, message => $line, category => $cat );
}

__END__

=head1 NAME 

scribe_cat.pl - Reads log messages from standard input and sends to a scribe instance

=head1 SYNOPSIS

  scribe_cat.pl --host=HOST --port=PORT --level=LEVEL --category=CATEGORY

  # Example Apache CustomLog entry
  CustomLog "|scribe_cat.pl --category=www" "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\""

=head1 DESCRIPTION

A simple script that uses the functionality of Log::Dispatch::Scribe
to read from standard input and send to a scribe instance.  Offers
categorisation by regular expression match on the log message.

=head2 Apache Logging

This script is suitable for use with Apache httpd for piped logging
per the CustomLog example shown above.

Note that special characters in the command given in the Apache configuration file need to be escaped; for example, this command line:

  /usr/local/bin/scribe_cat.pl --category-re 'local$1= /\?p=([^ ]+)'

would be specified in the configuration file as:

  CustomLog "|/usr/local/bin/scribe_cat.pl --category-re \'local$1= /\\\\?p=([^ ]+)\'" combined

=head1 OPTIONS

=over 4

=item --host, --port

Host and port of Scribe server.  Defaults to localhost, port 1463.

=item --category=CATEGORY

Default Scribe logging category, used where there is no --category-re or no match on any given category-re.

=item --category-re CATEGORY=REGEXP [ --category-re CATEGORY=REGEXP ...]

Specify a mapping from regular expression match on each log message to
category name.  --category-re may be specified more than once to
specify a set of mappings.  Each mapping is of the form
CATEGORY=REGEXP, where CATEGORY is the category name and may include
substitutions from the matching expression, using $1, $2 etc. REGEXP
is any Perl regexp, using () for grouping to create the $1, $2
references.

The regular expressions are tried in the order that they are specified
on the command line, and the first match is used.

Example: 

    --category-re 'foo$1=www\.([^ ]+)' --category-re bar=BAR --category-re baz='(?i:BAZ)'

  Log Message       |     Category  |     Notes
  --------------------------------------------------
  www.acme.com xyz  | fooacme.com   | Back-subst of acme.com
  my new BAR baz    | bar           | Matches BAR before BAZ
  bar my new baz    | baz           | Case insensitive match on bar


=item --retry-plan-a=MODE, --retry-plan-b=MODE, --retry-buffer-size=SIZE, --retry-count=COUNT, --retry-delay=DELAY

See L<Log::Dispatch::Scribe> for full description of these options.

=item --debug, --debug=FILE

Enable debugging to standard error or to file.

=back

=head1 SEE ALSO

L<Log::Dispatch::Scribe>, L<File::Tail::Scribe>

Apache httpd piped log documentation, L<http://httpd.apache.org/docs/2.2/logs.html#piped>

=head1 AUTHOR

Jon Schutz, C<< <jon at jschutz.net> >> L<http://notes.jschutz.net>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-log-logdispatch-scribe at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Dispatch-Scribe>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc scribe_cat.pl


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Dispatch-Scribe>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Dispatch-Scribe>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Dispatch-Scribe>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Dispatch-Scribe/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jon Schutz, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

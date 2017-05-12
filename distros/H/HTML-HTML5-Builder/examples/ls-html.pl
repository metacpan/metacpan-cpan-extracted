#!/usr/bin/perl

use Cwd;
use DateTime;
use DateTime::Format::Strptime;
use HTML::HTML5::Builder qw[html head title style meta body h1 :tabular tr time strong];

my @dirs = @ARGV;
@dirs = getcwd unless @dirs;

my @headers = qw(name size mtime mode uid gid);

my $fmt = DateTime::Format::Strptime->new(pattern => '%F %T');

print html(
	head(
		title("ls-html.pl ", \@dirs),
		style(
			-type  => 'text/css',
			-media => 'screen',
			q{
				body { color: black; background: #ffc; font-family: "Helvetica", sans-serif; }
				table { border: 2px solid black; border-collapse: collapse; }
				caption { padding: 4px; font-weight: bold; font-style: italic; font-size: 85%; }
				th, td { border: 1px solid #666; padding: 2px 4px; }
				th { color: white; background: #666; }
				td { color: black; background: white; }
				.field2, .field4, .field5, .field6 { text-align: right; }
			}),
		map { meta(-name=>'dirname', -content=>$_) } @dirs
		),
	body(
		h1('ls-html.pl'),
		map {
			my $dir   = $_;
			my @files = sort <$dir/*>;
			table(
				caption($dir),
				thead(&tr(map {th($_)} @headers)),
				tbody(
					map {
						my $is_dir = -d $_;
						my @stat = stat (my $file = $_);
						$file =~ s#^(.*)/([^/]+)$#$2#;
						my $i = 0;
						&tr(
							map { $i++; td(-class => "field$i", $_); }
								$is_dir ? strong($file) : $file,
								$is_dir ? ' ' : $stat[7],
								&time( DateTime->from_epoch(epoch => $stat[9], formatter => $fmt) ),
								sprintf('%06o', $stat[2]),
								$stat[4],
								$stat[5],
							)
						} @files,
					),
			);
			} @dirs,
		),
	)
	->toString  # use toStringHTML for HTML5.
	;

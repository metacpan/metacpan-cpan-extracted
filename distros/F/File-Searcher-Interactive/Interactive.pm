package File::Searcher::Interactive;
use File::Searcher;
use Term::Prompt;
use Term::ANSIColor qw/:constants/;
$Term::ANSIColor::AUTORESET = 1;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(File::Searcher);
$VERSION = '0.9';


sub interactive{
	my $self = shift;
	$self->{_interactive} = 1;
	$self->start;
}

sub _process_file{
	my $self = shift;
	my ($file) = @_;
	my @expressions = @{$self->{_expressions}};

	my $contents='';
	$self->_backup($file) if $self->do_backup;
	$self->_archive($file) if $self->do_archive;
	$self->{_search}->add_files_matched($file);

	my $lock = new File::Flock $file;
	open(FILE, $file) || die "Cannot read file $file\n";
	my @contents = <FILE>;
	$contents = join("", @contents);
	foreach my $expression (@expressions)
	{
		next if $self->{_search}->expression($expression)->skip_expression;
		my ($match_cnt,$replace_cnt,$skip_next,$do_file,$do_all,$new_match_cnt,$re_do) = (0)x7;
		$self->{_search}->expression($expression)->add_files_matched($file);
		$do_all = $self->expression($expression)->do_all;
		my $preview = '';
		my $more = 1;
		my ($search, $replace, $options_search, $options_replace) = $self->_get_search($expression);
		$search = "(?$options_search)$search";
		while($contents =~ m/$search/g)
		{
			my $match = Match->new(match=>$&,pre=>$`,post=>$',last=>$+,start_offset=>@-,end_offset=>@+,contents=>$contents);

			my $return_status = 0;
			$return_status = $self->{_on_expression_match}->($match, $self->{_search}->expression($expression)) if $do_file != 1 && $do_all != 1 && $new_match_cnt < 1;
			$contents = $return_status and next if $return_status !~ /\d+/ && $return_status ne '';
			$self->expression($expression)->do_all(1) and $do_all = 1 if $return_status == 100;
			$do_file = 1 if $return_status == 10;
			$self->expression($expression)->skip_expression(1) and last if $return_status == -100;
			last if $return_status == -10;
			$skip_next = 1 if $return_status == -1;

			$skip_next = 1 if $match->match eq $replace;
			$skip_next = 1 if $new_match_cnt > 0;

			my $short_pre = substr($match->pre, (-25*$more), (25*$more));
			my $short_post = substr($match->post, 0, 25*$more);
			my $message = $short_pre; $message .= $re_do ? BOLD $preview : BOLD $match->match; $message .= $short_post;
			unless($do_file || $do_all || $skip_next)
			{
				my $out = BOLD $file ."\n";	$out.=$message; $out.="\n--------------\n"; $out .= BOLD $replace . "\n";
				print $out;
			}
			my $prompt = BOLD "[Y]"; $prompt .= "Replace ";	$prompt .= BOLD "[A]"; $prompt .= "All In File "; $prompt .= BOLD "[Z]"; $prompt .= "All Files\n "; $prompt .= BOLD "[P]"; $prompt .= "Preview "; $prompt .= BOLD "[M]"; $prompt .= "More\n";
			my $result = '';
			$result = "Y" if $do_file || $do_all;
			$result = "Next" if $skip_next;
			$result = &Term::Prompt::prompt("x", "$prompt", "", "Next") unless $result;
			$more = 1 if $result !~ /M/i && $skip_next != 1;
			$re_do = 0 unless $skip_next;

			if($result =~ /A/i){
				my $v_message = "Are you sure you want to replace "; $v_message .= BOLD "ALL "; $v_message .= "occurances of $search in "; $v_message .= BOLD "THIS "; $v_message .= "file";
				my $verify = &prompt("y", "$v_message", "", "n");
				$do_file = 1 if $verify == 1;
				$contents = $match->pre . $match->match . $match->post if $verify != 1;
			}
			elsif($result =~ /Z/i){
				my $v_message = "Are you sure you want to replace "; $v_message .= BOLD "ALL "; $v_message .= "occurances of $search in "; $v_message .= BOLD "ALL "; $v_message .= "remaining files";
				my $verify = &prompt("y", "$v_message", "", "No");
				$do_all = 1 if $verify == 1;
				$self->expression($expression)->do_all(1) if $verify == 1;
				$contents = $match->pre . $match->match . $match->post if $verify != 1;
			}
			elsif($result =~ /P/i){
				$re_do = 1;
				my $body = $match->match;
				eval ("\$body =~ s/$search/$replace/$options_replace");
				$contents = $match->pre . $match->match . $match->post;
				$new_match_cnt = $match_cnt+1;
				$preview = $body;
			}
			elsif($result =~ /m/i){
				$re_do = 1;
				$more = $more*2;
				$contents = $match->pre . $match->match . $match->post;
				$new_match_cnt = $match_cnt+1;
				$preview = $match->match;
			}

			$match_cnt++ unless $skip_next == 1 || $re_do == 1;
			if($result =~ /y/i || ($result =~ /Z/i && $do_all) || ($result =~ /A/i && $do_file))
			{
				my $body = $match->match;
				eval ("\$body =~ s/$search/$replace/$options_replace");
				$replace_cnt++;
				$contents = $match->pre . $body . $match->post;
				$new_match_cnt = $match_cnt+1;
			}
			$new_match_cnt--;
			$skip_next = 0;
		}
		$self->{_search}->expression($expression)->add_files_replaced($file) if $replace_cnt > 0;
		$self->{_search}->expression($expression)->replacements($file, $replace_cnt);
		$self->{_search}->expression($expression)->matches($file, $match_cnt);
	}
	close(FILE);
	if($self->{_search}->do_replace)
	{
		open(FILE, ">$file") || die "Cannot read file $file\n";
		print FILE $contents;
		close(FILE);
	}
}


1;
__END__

=head1 NAME

File::Searcher::Interactive -- Searches for files and performs
search/replacements on matching files, uses terminal to make the
searches interactive.

=head1 SYNOPSIS

        use File::Searcher::Interactive;
        my $search = File::Searcher->new('*.cgi');
        $search->add_expression(name=>'street', search=>'1234 Easy St.', replace=>'456 Hard Way', options=>'i');
        $search->add_expression(name=>'department', search=>'(Dept\.|Department)(\s+)(\d+)', replace=>'$1$2$3', options=>'im');
        $search->add_expression(name=>'place', search=>'Portland, OR(.*?)97212', replace=>'Vicksburg, MI${1}49097', options=>'is');
        $search->interactive;
        # $search->start; SEE File::Searcher
        @files_matched = $search->files_matched;
        print "Files Matched\n";
        print "\t" . join("\n\t", @files_matched) . "\n";
        print "Total Files:\t" . $search->file_cnt . "\n";
        print "Directories:\t" . $search->dir_cnt . "\n";
        my @files_replaced = $search->expression('street')->files_replaced;my @files_replaced = $search->expression($expression)->files_replaced;
        my %matches = $search->expression('street')->matches;
        my %replacements = $search->expression('street')->replacements;

=head1 DESCRIPTION

C<File::Searcher::Interactive> is a sub-class of C<File::Searcher>
which allows for the traversing of a directory tree for files matching
a Perl regular expression. When a match is found, the statistics are
stored and if the file is a text file a series of searches and
replacements can be performed. C<File::Searcher::Interactive> uses the
terminal to prompt the user for interactive replacements.

=head1 USAGE

B</path/to/file.txt>

some pre text is here...

the B<current match> is bold

and some post text is here...

--------------

B<current replace(.*?)expression>

B<[Y]>Replace B<[A]>All In File B<[Z]>All Files B<[P]>Preview
B<[M]>More [default Next]

[Y]Replace - Replaces current match, with current replace expression

[A]All In File - Replaces all matches for this expression in this file

[Z]All Files - Replaces all matches for this expression in all files

[P]Preview - Preview the change, before deciding to proceed

[M]More - Show more pre-text and post-text

=head1 CAVEATS

=over

=item * Be sure to test on your terminal before "guaranteed"
reliability

=item * Super complex regular expressions probably won't work the way
you think they will.

=back

=head1 BUGS

Let me know...

=head1 TO DO

=over

=item * More advanced functionality

=item * More reporting (line numbers, etc.)

=item * Find Term::Prompt fix

=back

=head1 SEE ALSO

File::Searcher, L<Term::ANSIColor|Class::Classless>, Term::Prompt

=head1 COPYRIGHT

Copyright 2000, Adam Stubbs

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. Please email me if you find this
module useful.

=head1 AUTHOR

Adam Stubbs, C<astubbs@advantagecommunication.com
(mailto:astubbs@advantagecommunication.com)>

=head1 Notes

Version 0.9, Last Updated November 14, 2000

=cut

package File::Searcher;

use File::Find;
use File::Copy;
use File::Flock;
use Class::Struct;
use Class::Generate qw(class subclass);
use Carp;
use strict;
use vars qw($VERSION $DEBUG $AUTOLOAD);

$VERSION = '0.92';
$DEBUG=0;


struct Stats => {device_code=>'$', inode_number=>'$', mode_flags=>'$', link_cnt=>'$', user_id=>'$', group_id=>'$', device_type=>'$', size_bytes=>'$', time_access_seconds=>'$', time_modified_seconds=>'$', time_status_seconds=>'$', block_system=>'$', block_file=>'$', time_access_string=>'$', time_modified_string=>'$', time_status_string=>'$', mode_string=>'$',};
struct Properties => {readable_e=>'$', writable_e=>'$', executable_e=>'$', readable_r=>'$', writable_r=>'$', executable_r=>'$', owned_e=>'$', owned_r=>'$', exist=>'$', exist_non_zero=>'$', zero_size=>'$', file=>'$', directory=>'$', link_=>'$', pipe_=>'$', socket_=>'$', block=>'$', character=>'$', setuid_bit=>'$', setgid_bit=>'$', sticky_bit=>'$', opened_tty=>'$', text=>'$', binary=>'$', stats=>'Stats', path=>'$', dir=>'$', name=>'$',};
struct Match => {match=>'$',pre=>'$',post=>'$',last=>'$',start_offset=>'$',end_offset=>'$',contents=>'$',};
class Expression=>{
	search=>{type=>'$', required=>1, default=>'""'},
	replace=>{type=>'$', required=>1, default=>'""'},
	options=>{type=>'$', required=>1, default=>'""'},
	eval_replacement=>{type=>'$', required=>0},
	case_insensitive=>{type=>'$', required=>0},
	multiline=>{type=>'$', required=>0},
	singleline=>{type=>'$', required=>0},
	repeat=>{type=>'$', required=>0},
	extend=>{type=>'$', required=>0},
	do_all=>{type=>'$', default=>'0'},
	skip_expression=>{type=>'$', default=>'0'},
	files_matched=>{type=>'@'},
	files_replaced=>{type=>'@'},
	replacements=>{type=>'%'},
	matches=>{type=>'%'},
};
class Search=>{
	start_directory=>{type=>'$',default=>"'./'"},
	backup_extension=>{type=>'$',default=>"'.bak'"},
	do_backup=>{type=>'$', default=>'0'},
	recurse_subs=>{type=>'$', default=>'1'},
	do_replace=>{type=>'$', default=>'0'},
	log_mode=>{type=>'$', default=>'111'},
	do_archive=>{type=>'$', default=>'0'},
	archive=>{type=>'$'},
	# expression
	expression=>{type=>'%Expression'},
	# constructor
	file_expression=>{type=>'$'},
	files=>{type=>'@'},
	# reports
	files_matched=>{type=>'@'},
	file_cnt=>{type=>'$', default=>'0'},
	file_text_cnt=>{type=>'$', default=>'0'},
	file_binary_cnt=>{type=>'$', default=>'0'},
	file_unknown_cnt=>{type=>'$', default=>'0'},
	unknown_cnt=>{type=>'$', default=>'0'},
	link_cnt=>{type=>'$', default=>'0'},
	dir_cnt=>{type=>'$', default=>'0'},
	socket_cnt=>{type=>'$', default=>'0'},
	pipe_cnt=>{type=>'$', default=>'0'},
};


sub new{

	my $class = shift;
	my $self = {};
	bless $self, $class;

	# new(\@files); explicit file list (array ref context)
	# new('*.html'); file match expression (scalar context)
	# new(var=>val,var=>val); search variables (list context)
	# new(\@files, {var=>val,var=>val});
	# new('*.html', {var=>val,var=>val});
	my($files);
	my $file_expression = '';
	if(ref $_[1] eq 'HASH')
	{
		# new(\@files, {var=>val,var=>val});
		if(ref $_[0] eq 'ARRAY'){($files) = shift;}
		# new('*.html', {var=>val,var=>val});
		else{($file_expression)=shift;}
		my ($options) = shift;
		foreach (keys %{$options}){push(@_, $_); push(@_, $options->{$_});}
	}
	elsif(ref $_[0] eq 'ARRAY'){$files = shift;}						# new(\@files);
	elsif(scalar(@_) == 1){$file_expression = shift;} 						# new('*.html');
	$self->{_search} = Search->new(@_); # @_ will be nothing || list of options
	$file_expression = $file_expression || $self->file_expression;
	$file_expression =~ s/([^\\])\./$1\\./g;
	$file_expression =~ s/^\*/.*/;
	$file_expression =~ s/\.\./\./g;
	$self->file_expression($file_expression);
	$self->files(\@{$files}) unless $self->files > 0;
	$self->start_directory($self->_get_cwd()) if $self->start_directory eq './';
	$self->{_on_file_match} = sub {return 1;};
	$self->{_on_expression_match} = sub {return 1;};
	$self->{_interactive} = 0;
	$self->{_expressions} = [];

	return $self;
}

sub add_expression{
	my $self = shift;
	my (@options) = @_;
	my @args = ();
	my $expression_name;

	while(@options)
	{
		my $name = shift @options;
		my $val  = shift @options;
		if($name =~ /name/i){$expression_name = $val;}
		else{push(@args, $name); push(@args, $val);}
	}
	my $expression = Expression->new(@args);
	push(@{$self->{_expressions}}, $expression_name) unless $self->{_search}->expression($expression_name);
	$self->{_search}->expression($expression_name, $expression);

}

sub on_file_match{
	my $self = shift;
	my ($sub_ref) = @_;
	$self->{_on_file_match} = $sub_ref if @_;
}

sub on_expression_match{
	my $self = shift;
	my ($sub_ref) = @_;
	$self->{_on_expression_match} = $sub_ref if @_;
}

sub get_expressions{
	my $self = shift;
	my @expressions = $self->{_search}->expression_keys;
	return \@expressions;
}

sub start{
	my $self = shift;
	&find(sub {$self->_find_file(@_)}, $self->start_directory);
}

sub _find_file{
	my $self = shift;

	my $fullFileDir = $File::Find::dir;
	my $fullFilePath = $File::Find::name;
	return if $fullFileDir ne $self->start_directory && $self->recurse_subs == 0;
	my $extension = $self->backup_extension;
	return if $fullFilePath =~ /$extension$/;
	my $file_expression = $self->file_expression || '';
	my @files = $self->files;
	my $file_pass = 0;
	return if $file_expression ne '' && $fullFilePath !~ /$file_expression/;
	foreach my $file (@files)
	{$file_pass = 1 if $fullFilePath =~ /\b$file\b/;}
	return if $file_pass != 1 && @files > 0;


	$self->_add_file($fullFilePath);
	$self->_get_properties($fullFilePath);
	$self->_get_stats($fullFilePath) if $self->{_files}->{$fullFilePath}->file;
	return unless $self->{_on_file_match}->($self->{_files}->{$fullFilePath});

	if($self->{_files}->{$fullFilePath}->file)
	{
		my $fileName = $fullFilePath;
		$fileName =~ s/$fullFileDir//;
		$fileName =~ s/^\///;
		$self->{_files}->{$fullFilePath}->dir($fullFileDir);
		$self->{_files}->{$fullFilePath}->name($fileName);
		if($self->{_files}->{$fullFilePath}->text)
		{
			$self->{_search}->file_text_cnt($self->{_search}->file_text_cnt+1);
			$self->_process_file($fullFilePath);
		}
		elsif($self->{_files}->{$fullFilePath}->binary)
		{
			$self->{_search}->file_binary_cnt($self->{_search}->file_binary_cnt+1);
		}
		else
		{
			$self->{_search}->file_unknown_cnt($self->{_search}->file_unknown_cnt+1);
		}
		$self->{_search}->file_cnt($self->{_search}->file_cnt+1);
		print "$fullFileDir/$fileName\n" if $DEBUG;

	}
	elsif($self->{_files}->{$fullFilePath}->directory)
	{
		$self->{_files}->{$fullFilePath}->dir($fullFilePath);
		$self->{_files}->{$fullFilePath}->name('');
		$self->{_search}->dir_cnt($self->{_search}->dir_cnt+1);
		print "$fullFilePath\n" if $DEBUG;
	}
	elsif($self->{_files}->{$fullFilePath}->socket_)
	{$self->{_search}->socket_cnt($self->{_search}->socket_cnt+1);}
	elsif($self->{_files}->{$fullFilePath}->pipe_)
	{$self->{_search}->pipe_cnt($self->{_search}->pipe_cnt+1);}
	elsif($self->{_files}->{$fullFilePath}->link_)
	{$self->{_search}->link_cnt($self->{_search}->link_cnt+1);}
	else
	{$self->{_search}->unknown_cnt($self->{_search}->unknown_cnt+1);}

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
		my ($match_cnt,$replace_cnt,$skip_next,$do_file,$do_all,$new_match_cnt) = (0)x6;
		$self->{_search}->expression($expression)->add_files_matched($file);
		$do_all = $self->expression($expression)->do_all;
		my ($search, $replace, $options_search, $options_replace) = $self->_get_search($expression);
		$search = "(?" . $options_search . ")" . $search;
		while($contents =~ m/$search/g)
		{
			my $match = Match->new(match=>$&,pre=>$`,post=>$',last=>$+,start_offset=>@-,end_offset=>@+,contents=>$contents);
			# to support old perl
			$match->match("$&"); $match->pre("$`"); $match->post("$'"); $match->last("$+"); $match->start_offset("@-"); $match->end_offset("@+"); $match->contents("$contents");
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
			unless($skip_next)
			{
				my $body = $match->match;
				eval ("\$body =~ s/$search/$replace/$options_replace");
				$replace_cnt++;
				$match_cnt++;
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

sub _get_search{
	my $self = shift;
	my ($expression) = @_;
	my $options = $self->{_search}->expression($expression)->options || '';
	my $search = $self->{_search}->expression($expression)->search || '';
	my $replace = $self->{_search}->expression($expression)->replace || '';
	my $multiline = 1 if $self->{_search}->expression($expression)->multiline || $options =~ /m/;
	my $singleline = 1 if $self->{_search}->expression($expression)->singleline || $options =~ /s/;
	my $case_insensitive = 1 if $self->{_search}->expression($expression)->case_insensitive || $options =~ /i/;
	my $eval_replacement = 1 if $self->{_search}->expression($expression)->eval_replacement || $options =~ /e/;
	my $extend = 1 if $self->{_search}->expression($expression)->extend || $options =~ /x/;

	my $options_search = '';
	$options_search .= "m" if $multiline;
	$options_search .= "i" if $case_insensitive;
	$options_search .= "s" if $singleline;
	$options_search .= "x" if $extend;
	my $options_replace = $options_search;
	$options_replace .= "e" if $eval_replacement;

	return($search, $replace, $options_search, $options_replace);

}

sub _archive{
	my $self = shift;
	use Archive::Tar;
	my ($file) = @_;

	unless($self->{_search}->archive)
	{
		my $archive = $self->{_search}->archive(time . ".tgz");
		my $dir = $self->{_search}->start_directory;
		Archive::Tar->create_archive("$dir/$archive", 9, "$file");
		return;
	}
	my $tar = Archive::Tar->new();
	my $archive = $self->{_search}->archive;
	my $dir = $self->{_search}->start_directory;
	$archive = "$dir/$archive";
	$tar->read($archive,1);
	$tar->add_files($file);
	$tar->write($archive,9);
}

sub _backup{
	my $self = shift;
	my ($file) = @_;
	my $extension = $self->backup_extension;
	return if $file =~ /$extension$/;
	copy($file, $file . $extension);
}


sub _add_file{
	my $self = shift;
	my ($file) = @_;
	return if exists $self->{_files}->{$file};
	$self->{_files}->{$file} = Properties->new(readable_e=>'0',writable_e=>'0',executable_e=>'0',readable_r=>'0',writable_r=>'0',executable_r=>'0',owned_e=>'0',owned_r=>'0',exist=>'0',exist_non_zero=>'0',zero_size=>'0',file=>'0',directory=>'0',link_=>'0',pipe_=>'0',socket_=>'0',block=>'0',character=>'0',setuid_bit=>'0',setgid_bit=>'0',sticky_bit=>'0',opened_tty=>'0',text=>'0',binary=>'0',path=> $file,);
}


sub _get_properties{
	my $self = shift;
	my ($file) = @_;
	my %p = (readable_e=>'-r',writable_e=>'-w',executable_e=>'-x',readable_r=>'-R',writable_r=>'-W',executable_r=>'-x',owned_e=>'-o',owned_r=>'-O',exist=>'-e',exist_non_zero=>'-s',zero_size=>'-z',file=>'-f',directory=>'-d',link_=>'-l',pipe_=>'-p',socket_=>'-S',block=>'-b',character=>'-c',setuid_bit=>'-u',setgid_bit=>'-g',sticky_bit=>'-k',opened_tty=>'-t',text=>'-T',binary=>'-B',);
	foreach (keys %p){eval "\$self->{_files}->{\$file}->$_\(1) if $p{$_} \$file;";}
}

sub _get_stats{
	my $self = shift;
	my ($file) = @_;
	my @p = qw/device_code inode_number mode_flags link_cnt user_id group_id device_type size_bytes time_access_seconds time_modified_seconds time_status_seconds block_system block_file/;
	my($device_code, $inode_number, $mode_flags, $link_cnt, $user_id, $group_id, $device_type, $size_bytes, $time_access_seconds, $time_modified_seconds, $time_status_seconds, $block_system, $block_file)
		= stat($file);
		
	foreach (@p){eval("\$self->{_files}->{\$file}->stats(new Stats);"); }
	foreach (@p){eval("\$self->{_files}->{\$file}->stats->$_\(\$$_);"); }

	# extra stats
	$self->{_files}->{$file}->stats->time_access_string($self->_seconds_2_string_date($time_access_seconds));
	$self->{_files}->{$file}->stats->time_modified_string($self->_seconds_2_string_date($time_modified_seconds));
	$self->{_files}->{$file}->stats->time_status_string($self->_seconds_2_string_date($time_status_seconds));
	$self->{_files}->{$file}->stats->mode_string($self->_file_mode_string($mode_flags, $file));
}

sub _get_cwd{
	my $self = shift;
	require Cwd;
	return Cwd::getcwd;
}

sub _seconds_2_string_date{
	my $self = shift;
	my($time)=@_;
	require Time::localtime;
	$time=Time::localtime::ctime($time);
	return $time;
}


sub _file_mode_string{
	my $self = shift;
	my($mode, $filename) =@_;
	my($modestring);

	if (-l $filename){$modestring = "1";}
	elsif (-d $filename){$modestring = "d";}
	else{$modestring = "-";}
	my $oo = $mode & 07;
	my $go = ($mode >> 3) & 07;
	my $uo = ($mode >> 6) & 07;

	$modestring .= ("---", "--x", "-w-", "-wx", "r--", "r-x", "rw-", "rwx")[$uo];
	if (-u $filename){chop($modestring);$modestring .= "s"}
	$modestring .= ("---", "--x", "-w-", "-wx", "r--", "r-x", "rw-","rwx")[$go];
	if (-g $filename){chop($modestring);$modestring .= "s"}
	$modestring .= ("---", "--x", "-w-", "-wx", "r--", "r-x", "rw-","rwx")[$oo];

	return $modestring;
}

sub AUTOLOAD{
	my($package, $function) = ($AUTOLOAD =~ /(.*)::(.*)/);
	my($self, @args)= @_;
#	print "$AUTOLOAD, $self," . join(', ', @args) ."\n" if $DEBUG;
	return $self->{_search}->$function(@args);
	croak "An Undefined subroutine &$AUTOLOAD";
}

sub DESTROY{}

1;
__END__

=head1 NAME

File::Searcher -- Searches for files and performs search/replacements
on matching files

=head1 SYNOPSIS

        use File::Searcher;
        my $search = File::Searcher->new('*.cgi');
        $search->add_expression(name=>'street',
            search=>'1234 Easy St.',
            replace=>'456 Hard Way',
            options=>'i');
        $search->add_expression(name=>'department',
            search=>'(Dept\.|Department)(\s+)(\d+)',
            replace=>'$1$2$3',
            options=>'im');
        $search->add_expression(name=>'place',
            search=>'Portland, OR(.*?)97212',
            replace=>'Vicksburg, MI${1}49097',
            options=>'is');
        $search->start;
        # $search->interactive; SEE File::Searcher::Interactive
        @files_matched = $search->files_matched;
        print "Files Matched\n";
        print "\t" . join("\n\t", @files_matched) . "\n";
        print "Total Files:\t" . $search->file_cnt . "\n";
        print "Directories:\t" . $search->dir_cnt . "\n";
        my @files_replaced = $search->expression('street')->files_replaced;
        my @files_replaced = $search->expression($expression)->files_replaced;
        my %matches = $search->expression('street')->matches;
        my %replacements = $search->expression('street')->replacements;

=head1 DESCRIPTION

C<File::Searcher> allows for the traversing of a directory tree for
files matching a Perl regular expression. When a match is found, the
statistics are stored and if the file is a text file a series of
searches and replacements can be performed. C<File::Searcher> has
options that allow for backing-up / archiving files and has OO access
to reporting and statistics of matches and replacements.

=head1 USAGE

=head2 General Use

  # constructor - with options

  my $search = File::Searcher->new(
    file_expression=>'*.txt', # required unless files
    files=>\@files,                 # required unless file_expression
    start_directory=> '/path/to/dir',       # default './'
    backup_extension=> '~',             # default '.bak'
    do_backup=> '0',                # default 1 will create backup file
    recurse_subs=> '0',             # default 1 will recurse subs
    do_replace=> '1',               # default 0 will not replace matches
    log_mode=> '111',               # unimplemented
    archive=>'my_archive.tgz',          # default is /start_directory/(system time).tgz
    do_archive=> '1', # default 0 will not archive matched files
 );

  # constructor - with file expression

  my $search = File::Searcher->new('*.txt');

  # constructor - with ref to array of absolute paths

  my $search = File::Searcher->new(\@files);

The constructor comes in 3 flavors; with options, with file expression,
or reference to array of absolute paths. If you do not specify the
options in the constructor, they can be set by accessor methods.

   $search->start_directory('/path/to/dir');
   $search->backup_extension('~');
   $search->do_backup(0);
   $search->recurse_subs(0);
   $search->do_replace(1);
   $search->archive('my_archive.tgz');
   $search->do_archive(0);

Next, the series of expressions are set with options. Expressions will
be searched in the order which they are added to the search.

   $search->add_expression(
      name=>'street', # required
      search=>'1234 Easy St.',
      replace=>'456 Hard Way',
      case_insensitive=>1,
   );

    $search->add_expression(
      name=>'department',
      search=>'(Dept\.|Department)(\s+)(\d+)',
      replace=>'$1$2$3',
      case_insensitive=>1,
      multiline=>1,
    );

   $search->add_expression(
      name=>'place',
      search=>'Portland, OR(.*?)97212',
      replace=>'Vicksburg, MI${1}49097',
      singleline=>1,);

Expression options can be set in two ways:


   # as a single string
   ...add_expression(..., options=> 'ismx');

   # as named paramaters
   ...add_expression(..., singleline=>1, multiline=>1,case_insensitive=>1, extended=>1);

   # Run search

   $search->start;

=head2 Expanded Functionality

For expanded FUN-ctionality set references to subroutines to process
when a file match is encountered C<on_file_match> and when a search
expression is encountered C<on_expression_match>.


   $search->on_file_match(sub{
   my ($file) = @_;
    return 0 unless $file->writable_r; # writable by real id?
    return 0 unless $file->stats->size_bytes < 100;
    chmod(0777, $file->path);
    return 1;
   });
   # alternatively
   # $search->on_file_match(\&my_sub);


C<on_file_match> receives a file object with properties methods
(path, readable_e, writable_e, executable_e, readable_r, writable_r,
executable_r, owned_e, owned_r, exist, exist_non_zero, zero_size, file,
directory, link_, pipe_, socket_, block, character, setuid_bit,
setgid_bit, sticky_bit, opened_tty, text, binary)
if it is a file it also has stats methods (device_code, inode_number,
mode_flags, link_cnt, user_id, group_id, device_type, size_bytes,
time_access_seconds, time_modified_seconds, time_status_seconds,
block_system, block_file, time_access_string, time_modified_string,
time_status_string, mode_string)
returns 1 to continue processing files (i.e. look for matches to expressions)
returns 0 to move to next file

   $search->on_expression_match( sub{
    my ($match,$expression) = @_;
    return -100 if scalar($expression->files_replaced) > 7;
    return -10 if length($match->post) < 120;
    return 1 if $match->match =~ /special(.*?)case/;
    return 10 unless $match->contents =~ /special/;
    # this is sort of what this module does, but,hey!
    my $file_contents = $match->contents;
    eval("\$contents =~ s/$match->search/$match->replace/g$match->options;");
    return $contents;
   });

   # alternatively
   # $search->on_expression_match(\&my_sub);

C<on_expression_match> receives a C<match> object with methods(match, pre, post, last, start_offset, end_offset,contents),
C<expression> object access expression options (search, replace, options, %replacements, %matches, @files_replaced)

   returns -100 to ignore expression, and do not search for it again in any file
   returns -10 to skip to next file
   returns -1 to skip to next match (possibly next file)
   returns 1 to process match (as specified in $search object)
   returns 10 to process all matches in file
   returns 100 to process all occurences in all files
   returns $content (scalar) of file contents, overwrites contents (only to file if specified) and moves to next file


=head2 Reporting

To see what happened, for the search and each expression, access results.

   # search results reports

   @files_matched = $search->files_matched;
   print "Files Matched\n";
   print "\t" . join("\n\t", @files_matched) . "\n";
   print "Text Files:\t" . $search->file_text_cnt . "\n";
   print "Binary Files:\t" . $search->file_binary_cnt . "\n";
   print "Uknown Files:\t" . $search->file_unknown_cnt . "\n";
   print "Total Files:\t" . $search->file_cnt . "\n";
   print "Directories:\t" . $search->dir_cnt . "\n";
   print "Hard Links:\t" . $search->link_cnt . "\n";
   print "Sockets:\t" . $search->socket_cnt . "\n";
   print "Pipes:\t" . $search->pipe_cnt . "\n";
   print "Uknown Entries:\t" . $search->unknown_cnt . "\n";
   print "\n";

   # expression results reports


   foreach my $expression (@{$search->get_expressions}){

      my @files_replaced = $search->expression($expression)->files_replaced;
      my %matches = $search->expression($expression)->matches;
      my %replacements = $search->expression($expression)->replacements;

      print "Search/Replace:\t" .>
      $search->expression($expression)->search .
      "\t" . $search->expression($expression)->replace . "\n";

      print "\tNo Replacements Made\n" and next if @files_replaced < 1;
      print "\tFile\t\t\t\t\tMatches\tReplacements\n";

      foreach my $file (@files_replaced){
         print "\t$file\t\t$matches{$file}\t$replacements{$file}\n";
      }
        print "\n";
   }




=head1 CAVEATS

Super complex regular expressions probably won't work the way you think
they will.

=head1 BUGS

Let me know...

=head1 TO DO

=over 4

=item * More advanced functionality

=item * More reporting (line numbers, etc.)

=item * Maybe get rid of Class::Generate

=back

=head1 SEE ALSO

File::Searcher::Interactive, L<File::Find|Class::Classless>,
File::Copy, File::Flock, Class::Struct::FIELDS, Class::Generate, Cwd,
Time::localtime, Archive::Tar

=head1 COPYRIGHT

Copyright 2000, Adam Stubbs
This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. Please email me if you find this
module useful.

=head1 AUTHOR

Adam Stubbs, C<astubbs@advantagecommunication.com>
Version 0.91, Last Updated Tue Sep 25 23:08:50 EDT 2001

=cut

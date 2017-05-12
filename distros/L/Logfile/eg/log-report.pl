#!/usr/local/bin/perl

require CGI;

my $q = new CGI;

if($q->path_info) {
    $file = $q->path_translated;
    open(FH, $file) || die "open '$file' $!";
    $fh = \*FH;
}
else { $fh = \*DATA }

%ConfigVars = map { $_,1 } qw(Log);
%Log = ();
read_config($fh);

eval { require "Logfile/$Log{Server}.pm" };
die $@ if $@;

print  $q->header,
       $q->start_html('HTTPD Log report');
 
if($q->request_method eq "POST") {
    generate_log();
}
else {
    print_form();
}

print $q->end_html;

sub generate_log {
    my($file,$sort) = map { $q->param($_) || "" } qw(File Sort);
    my $list = [$q->param('List')];
    
    $sort ||= "Date";
    $file ||= $Log{File};	
    $list = [qw(Host)] unless @$list;;
    my $log = new Logfile::Apache  
	File  => $file,
	Group => [qw(File Host Domain Date User)];

    print "<pre>\n";
    $log->report(Group => "Date", Sort => $sort, 
		 List => $list);
    print "</pre>\n";   

}

sub print_form {
    my($method) = @_;
    my($resp,@html);
    print $q->startform(-script => $q->script_name),
        "<H3>HTTPD Log report</H3><hr>\n",
        "File: ", 
	$q->popup_menu(-name => 'File', 
			   -values => [$Log{File}, <$Log{Archive}/*.gz>]),
        "<p>List: ",
        $q->checkbox_group(-name => 'List', 
			       -values => [qw(Date File Host Domain User)]),
        "<p>Sort by: ",
        $q->radio_group(-name => 'Sort', 
			    -values => [qw(Date File Host Domain User)]),
        $q->submit('POSTACTION', " OK "),
        $q->endform; 
}		 

sub read_config {
    my($fh) = @_;
    my($hash,$key,$val);
    no strict 'refs';
    while(<$fh>) {
	clean(*_); next if /^$/;
	($hash,$key,$val) = split;
	unless(defined $ConfigVars{$hash}) {
	    die "Unknown configuration directive '$hash'";
	}
	$$hash{$key} = $val;
    }
}

sub clean { local(*_) = @_; chomp; s/#.*//; s/^\s+//; s/\s+$/ /; }

__END__

Log    Server   Apache
Log    File     /usr/www/80/logs/access_log
Log    Archive  /usr/www/log_archive/1996



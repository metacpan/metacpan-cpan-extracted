#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More;

use MIME::Tools;
use File::Path;
use File::Spec;
use File::Basename;
use MIME::WordDecoder qw(unmime);

use lib qw( ./t/ );
use Globby;

use MIME::Parser;

#print STDERR "\n";

### Verify directory paths:
(-d "testout") or die "missing testout directory\n";
my $output_dir = File::Spec->catdir(".", "testout", "Ref_t");

### Get messages to process:
my @refpaths = @ARGV;
if (!@refpaths) { 
    opendir DIR, "testmsgs" or die "opendir: $!\n";
    @refpaths = map { File::Spec->catfile(".", "testmsgs", $_) 
		      } grep /\w.*\.ref$/, readdir(DIR);
    closedir DIR; 
}

plan( tests => 2 * scalar(@refpaths) );

### For each reference:
foreach my $refpath (@refpaths) {

    ### Get message:
    my $msgpath = $refpath; $msgpath =~ s/\.ref$/.msg/;
#   print STDERR "   $msgpath\n";

    ### HACK HACK HACK: MailTools behaviour has changed!!!
    if ($msgpath =~ /hdr-fakeout.msg$/ &&
	$::Mail::Header::VERSION > 2.14) {
	    $refpath = 'testmsgs/hdr-fakeout-newmailtools-ref';
    }
    ### Get reference, as ref to array:
    my $ref = read_ref($refpath);
    if ($ref->{Parser}{Message}) {
	$msgpath = File::Spec->catfile(".", (split /\//, $ref->{Parser}{Message}));
    }
    # diag("Trying $refpath [$msgpath]\n");

    ### Create parser which outputs to testout/scratch:
    my $parser = MIME::Parser->new;
    $parser->output_dir($output_dir);
    $parser->extract_nested_messages($ref->{Parser}{ExtractNested});
    $parser->extract_uuencode($ref->{Parser}{ExtractUuencode});
    $parser->output_to_core(0);
    $parser->ignore_errors(0);

    ### Set character set:
    my $tgt = $ref->{Parser}{Charset} || 'ISO-8859-1';
    my $wd;
    if ($tgt =~ /^ISO-8859-(\d+)/) {
	$wd = new MIME::WordDecoder::ISO_8859 $1;
    }
    else {
	$wd = new MIME::WordDecoder([uc($tgt)   => 'KEEP',
				     'US-ASCII' => 'KEEP',
      				     '*'        => 'WARN']);
    }
    # diag("Default charset: $tgt");
    MIME::WordDecoder->default($wd);
	
    ### Pre-clean:    
    rmtree($output_dir);
    (-d $output_dir) or mkpath($output_dir) or die "mkpath $output_dir: $!\n";

    ### Parse:
    my $ent = eval { $parser->parse_open($msgpath) };
    my $parse_error = $@;

    ### Output parse log:
#    diag("PARSE LOG FOR $refpath [$msgpath]");
    if ($parser->results) {
#	diag($parser->results->msgs);
    }
    else {
	diag("Parse failed before results object was created");
    }

    ### Interpret results:
    if ($parse_error || !$ent) {
	ok($ref->{Msg}{Fail}, "$refpath, problem: $parse_error" );
    }
    else {
	# TODO: check_ref is evil
	my $ok = eval { check_ref($msgpath, $ent, $ref) };
	if( $@ ) {
		diag("Eval failed: $@");
	}
	ok($ok, "$refpath Message => $msgpath, Parser => " . ($ref->{Parser}{Name} || 'default'));
    }

    ### Is purge working?
    my @a_files = list_dir($output_dir);
    my @p_files = $parser->filer->purgeable;
    $parser->filer->purge;
    my @z_files = list_dir($output_dir);
    is(@z_files, 0, 'Did purge work?');
	
    ### Cleanup for real:
    rmtree($output_dir);
}

### Done!
exit(0);
1;

#------------------------------

sub list_dir {
    my $dir = shift;
    opendir DIR, $dir or die "opendir $dir; $!\n";
    my @files = grep !/^\.+$/, readdir DIR;
    closedir DIR;
    return sort @files;
}

#------------------------------

sub read_ref {
    my $path = shift;
    open IN, "<$path" or die "open $path: $!\n";
    my $expr = join('', <IN>);
    close IN;
    my $ref = eval $expr; $@ and die "syntax error in $path\n";
    $ref;
}

#------------------------------

sub trim {
    local $_ = shift;
    s/^\s*//;
    s/\s*$//;
    $_;
}

#------------------------------
# TODO: replace with cmp_deeply from Test::Deep?
sub check_ref {
    my ($msgpath, $ent, $ref) = @_;

    my $wd = supported MIME::WordDecoder 'UTF-8';
    ### For each Msg in the ref:
  MSG:
    foreach my $partname (sort keys %$ref) {
	$partname =~ /^(Msg|Part_)/ or next;
	my $msg_ref = $ref->{$partname};
	my $part    = get_part($ent, $partname) || 
	    die "no such part: $partname\n";
	my $head    = $part->head; $head->unfold;
	my $body    = $part->bodyhandle;

	### For each attribute in the Msg:
      ATTR:
	foreach (sort keys %$msg_ref) {

	    my $want = $msg_ref->{$_};
	    my $got = undef;

	    if    (/^Boundary$/) { 
		$got = $head->multipart_boundary;
	    }
	    elsif (/^From$/)     { 
		$got  = trim($head->get("From", 0)); 
		$want = trim($want); 
	    }
	    elsif (/^To$/)       { 
		$got  = trim($head->get("To", 0)); 
		$want = trim($want); 
	    }
	    elsif (/^Subject$/)  { 
		$got  = trim($head->get("Subject", 0));
		$want = trim($want); 
	    }
	    elsif (/^Charset$/)  { 
		$got = $head->mime_attr("content-type.charset"); 
	    }
	    elsif (/^Disposition$/) { 
		$got = $head->mime_attr("content-disposition"); 
	    }
	    elsif (/^Type$/)     {
		$got = $head->mime_type;
	    }
	    elsif (/^Encoding$/) {
		$got = $head->mime_encoding;
	    }
	    elsif (/^Filename$/) {
		$got = $head->recommended_filename; 
	    }
	    elsif (/^BodyFilename$/) {
		$got = (($body and $body->path) 
			? basename($body->path) 
			: undef);
	    }
	    elsif (/^Preamble$/) {
		$got = join('', @{$part->preamble});
	    }
	    elsif (/^Epilogue$/) {
		$got = join('', @{$part->epilogue});
	    }
	    elsif (/^Size$/)     { 
		if ($head->mime_type =~ m{^(text|message)}) {
#		    diag("Skipping Size evaluation in text message ".
#			    "due to variations in local newline ".
#			    "conventions\n\n");
		    next ATTR;
		}
		if ($body and $body->path) { $got = (-s $body->path) }
	    }
	    else {
		die "$partname: unrecognized reference attribute: $_\n";
	    }

	    ### Log this sub-test:
#	    diag("SUB-TEST: msg=$msgpath; part=$partname; attr=$_:\n");
#	    diag("  want: ".encode($want)."\n");
#	    diag("  got:  ".encode($got )."\n");
#	    diag("\n");

	    next ATTR if (!defined($want) and !defined($got));
	    next ATTR if ($want eq $got);
	    die "$partname: wanted qq{$want}, got qq{$got}\n";
	}
    }

    1;
}

# Encode a string
sub encode {
	local $_ = shift;
	return '<undef>' if !defined($_);

	s{([\n\t\x00-\x1F\x7F-\xFF\\\"])}
         {'\\'.sprintf("%02X",ord($1)) }exg;
        s{\\0A}{\\n}g;
	return qq{"$_"};
}

#------------------------------

sub get_part {
    my ($ent, $name) = @_;

    if ($name eq 'Msg') {
	return $ent;
    }
    elsif ($name =~ /^Part_(.*)$/) {
	my @path = split /_/, $1;
	my $part = $ent;
	while (@path) {
	    my $i = shift @path;
	    $part = $part->parts($i - 1);
	}
	return $part;
    }
    undef;   
}

1;


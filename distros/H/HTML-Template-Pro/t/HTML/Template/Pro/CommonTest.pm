package HTML::Template::Pro::CommonTest;

use strict;
use warnings;
use Carp;

use Test;
use File::Spec;
use File::Path;
use HTML::Template::Pro qw/:const/;
#use Data::Dumper;
use JSON;
require Exporter;
use vars qw/@ISA @EXPORT/;
@ISA=qw/Exporter/;
@EXPORT =qw/test_tmpl test_tmpl_std test_tmpl_expr dryrun/;

use vars qw/$DumpDir $DumpDir_no_cs/;
$DumpDir='json-cs';
$DumpDir_no_cs='json';

#$Data::Dumper::Terse=1;
#$Data::Dumper::Indent=1;
#$Data::Dumper::Useqq=1;
#$Data::Dumper::Pair = ' : ';

#########################

my $DEBUG=$ENV{HTP_DEBUG};
$DEBUG||=0;

sub test_tmpl {
    my $file=shift;
    my $optref=shift;
    my @param=@_;
    my $tmpl;
    print "\n--------------- Test: $file ---------------------\n";
    chdir 'templates-Pro';
    $tmpl=HTML::Template::Pro->new(filename=>$file.'.tmpl',debug=>$DEBUG, @$optref);
    $tmpl->param(@param);
    &dryrun($tmpl,$file);
    $ENV{HTP_DUMP} && &dump_test ($file,{@$optref},{@param});
    chdir '..';
}

sub test_tmpl_expr {
    my $file=shift;
    my $tmpl;
    print "\n--------------- Test: $file ---------------------\n";
    chdir 'templates-Pro';
    $tmpl=HTML::Template::Pro->new(filename=>$file.'.tmpl', loop_context_vars=>1, case_sensitive=>1,tmpl_var_case=>ASK_NAME_UPPERCASE|ASK_NAME_AS_IS,debug=>$DEBUG, functions=>{'hello' => sub { return "hi, $_[0]!" }});
    $tmpl->param(@_);
    # per-object extension
    $tmpl->register_function('per_object_call' => sub { return shift()."-arg"});
    $tmpl->register_function('perobjectcall2' => sub { return shift()."-arg"});
    &dryrun($tmpl,$file);
    chdir '..';
}

my $case_ext = [
    loop_context_vars=>1,
    case_sensitive=>0,
    ];
my $case_int = [
    loop_context_vars=>1,
    case_sensitive=>1,
    tmpl_var_case=>ASK_NAME_UPPERCASE,
    ];

sub test_tmpl_std {
    my ($file,@args)=@_;
    &test_tmpl($file, $case_ext, @args);
    &test_tmpl($file, $case_int, @args);
}

sub dryrun {
    my $tmpl=shift;
    my $file=shift;
    open (OUTFILE, ">$file.raw") || die "can't open $file.raw: $!";
    binmode (OUTFILE);
    $tmpl->output(print_to => *OUTFILE);
    close (OUTFILE) || die "can't close $file.raw: $!";
    my $fileout = &catfile("$file.out");
    my $files_equal=&catfile("$file.raw") eq $fileout;
    if ($files_equal) {
	ok($files_equal) && unlink "$file.raw";
    } else {
	if (-x '/usr/bin/diff') {
	    print STDERR `diff -u $file.out $file.raw`;
	} else {
	    print STDERR "# >>> ---$file.raw---\nTODO: diff here\n>>> ---end $file.raw---\n";
	}
    }
    my $output=$tmpl->output();
    ok (defined $output and $output eq $fileout);
}

sub catfile {
    my $file=shift;
    open (INFILE, $file) || die "can't open $file: $!";
    binmode (INFILE);
    local $/;
    my $catfile=<INFILE>;
    close (INFILE) || die "can't close $file: $!";
    return $catfile;
}

my %filename_counter;
$0=~/([\w_-]+)(?:\.t)$/;
my $dump_prefix = $1 ? "$1-" : '';
sub _dump_file_name {
    my ($DumpDir,$file) = @_;
    my $plain=$file;
    $plain=~s![\\/:]!_!g;
    return File::Spec->catfile($DumpDir, 
      $dump_prefix.$plain.'-'.sprintf("%.2d",++$filename_counter{$file}).'.json');
}

sub dump_test {
    my ($file,$optref,$paramref) = @_;
    mkpath ([$DumpDir,$DumpDir_no_cs]);
    my $tojson = {
	'file' => $file,
	'options' => $optref,
	'params' => $paramref,
    };
    &__dump_json(&_dump_file_name($DumpDir,$file), $tojson);
    my $case_sensitive=$optref->{'case_sensitive'};
    if (defined $case_sensitive) {
	delete $optref->{'case_sensitive'};
	$optref->{'tmpl_var_case'}=ASK_NAME_UPPERCASE unless $case_sensitive;
    }
    &__dump_json(&_dump_file_name($DumpDir_no_cs,$file), $tojson);
}

sub __dump_json {
    my ($dump_file, $tojson) = @_;
    open FH, '>', $dump_file or die "can't open ($!) ".$dump_file;
    print FH to_json($tojson, {utf8 => 1, pretty => 1});
    close (FH) or die "can't close ($!) ".$dump_file;
}

### Local Variables: 
### mode: perl
### End: 


1;

__END__

#head1 NAME

HTML::Template::Pro::CommonTest - internal common test library

#head1 DESCRIPTION

internal common test library

#head1 AUTHOR

I. Vlasenko, E<lt>viy@altlinux.orgE<gt>

#head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by I. Yu. Vlasenko.

This library is free software; you can redistribute it and/or modify it under 
either the LGPL2+ or under the same terms as Perl itself, either Perl version 5.8.4 
or, at your option, any later version of Perl 5 you may have available.

#cut

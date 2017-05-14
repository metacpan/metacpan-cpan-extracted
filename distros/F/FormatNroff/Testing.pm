package HTML::Testing;

=head1 NAME

HTML::Testing - Test module to make test files simpler.

=head1 SYNOPSIS

A test file, simple.t may be created as follows:

 print "1..1\n";
 use strict;

 require HTML::FormatNroff;
 use HTML::Parse;
 require HTML::Testing;

 my $man_date = '20 Dec 97';
 my $name = "simple";

 my $html_source =<<END_INPUT;
 <HTML>
 <BODY>This is the body.</BODY>
 </HTML>
 END_INPUT

 my $expected = ".TH \"$name\" \"1\" \"$man_date\" \"FormatNroff\"  \n";  
 $expected .=<<END_EXPECTED;
 .PP
 This is the body.
 END_EXPECTED

 my $tester = new HTML::Testing(name => $name,
			        man_date => $man_date,
			        project => 'FormatNroff',
			        man_header => 1,
			        expected => $expected,
			        html_source => $html_source
				output => 'TestOutput',
			        );
 $tester->run_test();
 1;

=head1 DESCRIPTION

Running the test harness with this will result in the creation of the files
simple_expected.out, simple_actual.out and an html file corresponding to the
html_source (simple.html). In addition, the 
test will return 'ok' if they are the same, and 'not ok' if not. 

If the attribute html_file is specified, then html will be sourced from
that file instead of html_source, and no html file will be created.

=cut

use strict;
use Carp;

require HTML::FormatNroffSub;
use HTML::Parse;
use File::Path;

=head2 $testing = new HTML::Testing();

Create new test.

=cut

sub new {
    my($class, %attr) = @_;

    my $self = bless {	
	name => $attr{'name'},
	man_date => $attr{'man_date'},
	project => $attr{'project'} || "test",
	man_header => $attr{'man_header'},
	expected => $attr{'expected'},
	html_source => $attr{'html_source'},
	html_file => $attr{'html_file'},
	directory => 'TestOut',
    }, $class;

    if($self->{'directory'}) {
	mkpath($self->{'directory'});
    }
    return $self;
}

=head2 $testing->directory($value);

Set the directory for output (HTML, actual and expected output files)
to $value.

=cut

sub directory {
    my($self, $value) = @_;

    $self->{'directory'}  = $value;
}

sub create_files {
    my($self, $actual) = @_;

    my $dir = $self->{'directory'};
    if($dir) {
	$dir .= '/';
    } else {
	$dir = '';
    }

    open(FILE, ">${dir}$self->{name}_actual.out");
    print FILE $actual;
    close(FILE);

    open(FILE, ">${dir}$self->{name}_expected.out");
    print FILE $self->{'expected'};
    close(FILE);

    unless($self->{'html_file'}) {
	open(FILE, ">${dir}$self->{name}.html");
	print FILE $self->{'html_source'};
	close(FILE);
    }
}

=head2 $testing->run_test();

Run the test.

=cut

sub run_test {
    my($self) = @_;

    my $html;

    if($self->{'html_file'}) {
	print STDERR "Using file $self->{'html_file'}\n";
	$html = parse_htmlfile($self->{'html_file'});
    } else {
	$html = parse_html($self->{'html_source'});
    }

    unless($html) {
	print STDERR "No HTML?\n";
	print "not ok\n";
	return;
    }

    my $formatter = new HTML::FormatNroffSub(name => $self->{'name'}, 
					     project => $self->{'project'},
					     man_date => $self->{'man_date'},
					     man_header => $self->{'man_header'}
					     );
    my $actual = $formatter->format($html);

    $self->create_files($actual);

    if("$actual" ne "$self->{'expected'}") {
#	print STDERR "Actual=\"\n$actual\n\"";
#	print STDERR "Expected=\"\n$expected\n\"";
	print 'not ok';
    } else {
	print 'ok';
    }
}

=head1 COPYRIGHT

Copyright (c) 1997 Frederick Hirsch. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Frederick Hirsch <f.hirsch@opengroup.org>

=cut 

1;

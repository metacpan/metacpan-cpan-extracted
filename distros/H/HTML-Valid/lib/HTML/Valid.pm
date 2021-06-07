package HTML::Valid;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/sanitize_errors/;
%EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use warnings;
use strict;
use Carp;
use JSON::Parse 'read_json';
our $VERSION = '0.08';
require XSLoader;
XSLoader::load ('HTML::Valid', $VERSION);

sub new
{
    my ($class, %options) = @_;
    my $htv = html_valid_new ();
    bless $htv;
    for my $k (keys %options) {
	$htv->set_option ($k, $options{$k});
    }
    return $htv;
}

sub read_ok_options
{
    my $ok_options_file = __FILE__;
    $ok_options_file =~ s!Valid\.pm$!Valid/ok-options.json!;
    return read_json ($ok_options_file);
}

my $ok_options;

sub set_option
{
    my ($htv, $option, $value) = @_;
    $option =~ s/_/-/g;
    if (! $ok_options) {
	$ok_options = read_ok_options ();
    }
    if ($ok_options->{$option}) {
	$htv->set_option_unsafe ($option, $value);
    }
    else {
	warn "Unknown or disallowed option $option";
    }
}

# Private, sort the messy errors from HTML Tidy by line number, and
# remove useless messages.

sub sanitize_errors
{
    my ($errors) = @_;
    $errors =~ s/Info:.*\n//;
    $errors =~ s/(?:No|[0-9]+) warnings?\s*(?:and|or|,) (?:[0-9]+ )?errors? were found(?:\.|!)\n//;
    #	$errors =~ s/^.*missing.*doctype.*\n//gi;
    $errors =~ s/^\s*$//gsm;
    #	$errors =~ s/^[0-9]+ warning.*$//gsm;
    #	$errors =~ s/^line ([0-9]+)(.*)/$file:$1: $2/gm;
    $errors =~ s/^\n//gsm;
    # Work around disordered line numbering in HTML Tidy.
    my @errors = split /\n/, $errors;
    my %errors;
    for (@errors) {
	my $line = $_;
	$line =~ s/.*:([0-9]+):[0-9]+:.*$/$1/;
	$errors{$_} = $line;
    }
    @errors = sort {$errors{$a} <=> $errors{$b}} @errors;
    $errors = join "\n", @errors;
    return $errors . "\n";
}

1;

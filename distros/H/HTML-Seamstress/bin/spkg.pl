#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Cwd;
use HTML::Seamstress;
use File::Basename;
use File::Slurp;
use File::Spec;
use Data::Dumper;
use Pod::Usage;

our $VERSION = 1.0;

my $cmdline = join ' ', ($0, @ARGV);


my ($base_pkg, $base_pkg_root, $cvs_add, $base_append);

my $result = GetOptions (
  'base_pkg:s'      => \$base_pkg,
  'base_pkg_root:s' => \$base_pkg_root,
  'cvs_add!'        => \$cvs_add,
  'base_append:s'   => \$base_append,
  
);

$base_pkg ||= 'HTML::Seamstress::Base' ;

unshift @INC, $base_pkg_root if ($base_pkg_root) ;

eval "require $base_pkg";
if ($@) {
  pod2usage(
    -msg     => "Could not load $base_pkg: $@",
    -exitval => 2
   );
}


my $comp_root = Cwd::realpath($base_pkg->comp_root);
-d $comp_root or 
    die sprintf "$comp_root is not a directory... attempted to
locate it via \$base_pkg->comp_root: %s", $base_pkg->comp_root;
$comp_root =~ m!/$! or $comp_root = "$comp_root/";

my $html_file = shift or pod2usage(
  -msg     => 'Did not supply HTML file for packaging',
  -exitval => 2);


my $abs  = File::Spec->rel2abs($html_file);
my $file_regexp = qr/[.]html?/;
my ($name, $path, $suffix) = fileparse($abs, $file_regexp);
my $html_pkg = html_pkg($path);


sub _verbose
{

    print join('', @_);
    print "\n";
}

sub _debug
{

    print join('', @_);
    print "\n";
}

sub cvs_add {

  my $file = shift;

  my $syscmd = "cvs add $file ";
  system $syscmd;

}

sub use_lib {
  $base_pkg_root ? "use lib '$base_pkg_root'" : "" ;
}


sub relpath_to_file {
  substr($abs, length $comp_root) ;
}

sub use_base_qw {
  
  my $qw = $base_pkg;
  $qw .= " $base_append" if $base_append;
  $qw;

}

sub template {
<<'EOTEMPLATE';
package %s;

# cmdline: %s

use strict;
use warnings;

use base qw(Class::Prototyped HTML::Seamstress);


%s;
use base qw(%s); 
use vars qw($html);

our $tree;

#warn %s->comp_root(); 
#%s


#$html = __PACKAGE__->html(__FILE__ => 'html') ;
$html = __FILE__;

sub new {
#  my $file = __PACKAGE__->comp_root() . '%s' ;
  my $file = __PACKAGE__->html($html => 'html');

  -e $file or die "$file does not exist. Therefore cannot load";

  $tree =HTML::TreeBuilder->new;
  $tree->store_declarations;
  $tree->parse_file($file);
  $tree->eof;
  
  bless $tree, __PACKAGE__;
}

sub process {
  my ($tree, $c, $stash) = @_;

  use Data::Dumper;
  warn "PROCESS_TREE: ", $tree->as_HTML;

  # $tree->look_down(id => $_)->replace_content($stash->{$_})
  #     for qw(name date);

  $tree;
}

sub fixup {
  my ($tree, $c, $stash) = @_;

  $tree;
}




1;
EOTEMPLATE
}

sub fill_template {
  my $template = template;
  sprintf $template,
      $html_pkg,
      $cmdline,
      use_lib,
	  use_base_qw, $base_pkg, $base_pkg,
	      relpath_to_file

}



sub calc_outfile {
  my $html_file = shift;

  $html_file =~ s/$file_regexp/.pm/;
  $html_file;
}

sub html_pkg {

  my ($html_file_path) = @_;

  warn "comp_root........ " . $comp_root, $/;
  warn "html_file_path... " . $html_file_path, $/;
  warn "html_file........ " . $html_file, $/;
  warn "html_file sans... " . $name, $/;

  my $mp = substr($html_file_path, length $comp_root) ;

  $comp_root eq substr($html_file_path, 0, length $comp_root) or warn
      "WARNING: the comp_root and html_file_path are not equal for the extent of comp_root...
This may lead to incorrect calculations";

  $mp =~ s!/!::!g;
  $mp .= $name;
  $mp;

}

my $outfile = calc_outfile $html_file;
open O, ">$outfile" or die $!;
print O fill_template;

warn "$html_file compiled to package $html_pkg\n";

cvs_add $outfile if $cvs_add;


=head1 NAME

 spkg - Create Perl packages for HTML files for HTML::Seamstress manipulation

=head1 SYNOPSIS

 spkg [options] html_file

=head1 OPTIONS

=over

=item * base_pkg_root $base_pkg_root (optional)

The directory to add to C<@INC> so that C<base_pkg> is found

=item * base_append $base_append (optional)

a string which will be appended to C<$base_pkg> to form the argument to C<use base qw( )>

This is advanced stuff. 

=item * base_pkg $base_pkg (required)

The base package containing a method C<comp_root> which returns the absolute 
path to the HTML file to be processed.

=back

=head1 DESCRIPTION

L<Template> and L<HTML::Mason> both create objects which they configure with
an C<INCLUDE_PATH> or C<comp_root>, respectively. Seamstress leverages Perl's
standard include mechanism to find HTML files. As such, a C<base_pkg> with a
method that will allow runtime C<require>s of such packages is needed. 


=cut

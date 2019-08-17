use 5.014;

use strict;
use warnings;

use Cwd;
use File::Basename;
use File::Find;
use File::Spec::Functions ':ALL';
use Test::More;

# SETUP

sub lib {
  my $this = $0;
  my $home = getcwd;

  return catfile($home, 'lib');
}

sub list {
  my @list;

  find sub { push @list, $File::Find::name if -f }, lib();

  return (@list);
}

sub files {
  my (@files) = @_;

  return (map abs2rel($_, lib()), sort(@files));
}

sub headings {
  my ($file) = @_;

  my $re = 'head1';

  return (map { /^=(?:$re\s+)?(\w+)/ } source($file));
}

sub mods {
  my (@files) = @_;

  return (map type($_, 'pm'), files(@files));
}

sub pods {
  my (@files) = @_;

  return (map type($_, 'pod'), files(@files));
}

sub source {
  my ($file) = @_;

  open my $fh, '<', "$file" or die "Can't open $file $!";

  return (map { chomp; $_ } (<$fh>));
}

sub subroutines {
  my ($path) = @_;

  my $re = 'fun|method|sub';

  my %ignore = map +($_, 1), qw(
    BUILD
    BUILDARGS
    import
    new_columns
    new_commands
    new_data
    new_indices
    new_name
    new_relations
    render_column
    render_column_change
    render_column_name
    render_columns
    render_constraint
    render_constraints
    render_if_exists
    render_increments
    render_index_columns
    render_index_name
    render_new_column
    render_new_column_name
    render_new_table
    render_nullable
    render_primary
    render_relation
    render_relation_name
    render_table
    render_temporary
    render_type
  );

  my @files = map { /^(?:$re)\s+([a-zA-Z]\w+).*\{$/ } source("lib/$path.pm");

  return (grep !$ignore{$_}, @files);
}

sub test {
  my (@list) = @_;

  test_subroutines($_, [subroutines($_)]) for @list;

  return 1;
}

sub test_exists {
  my ($path, $subs) = @_;

  my $name = $path =~ s/\W+/_/gr;
  my @list = map catfile("t", "can", "${name}_$_.t"), @$subs;

  ok -f $_, "$_ exists" for @list;

  return;
}

sub test_sections {
  my ($path, $subs) = @_;

  my $name = $path =~ s/\W+/_/gr;
  my @list = map catfile("t", "can", "${name}_$_.t"), @$subs;

  for my $file (grep -f, @list) {
    my $headings = { map +($_, $_), headings($file) };

    ok exists $headings->{name}, "$file has pod name-section";
    ok exists $headings->{usage}, "$file has pod usage-section";
    ok exists $headings->{description}, "$file has pod description-section";
    ok exists $headings->{signature}, "$file has pod signature-section";
    ok exists $headings->{type}, "$file has pod type-section";
  }

  return;
}

sub test_subroutines {
  my ($path, $subs) = @_;

  test_exists($path, $subs);
  test_sections($path, $subs);

  return;
}

sub type {
  my ($file, $type) = @_;

  my @parts = split(/\./, $file, 2);

  return $parts[1] eq $type ? ($parts[0]) : ();
}

# TESTING

test(mods(list())) and done_testing;

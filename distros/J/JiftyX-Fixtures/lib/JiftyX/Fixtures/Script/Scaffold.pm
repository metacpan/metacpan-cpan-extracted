package JiftyX::Fixtures::Script::Scaffold;
our $VERSION = '0.07';

# ABSTRACT: scaffold subcommands

use warnings;
use strict;

use Jifty;
use Jifty::Everything;

use IO::File;
use File::Spec;
use File::Basename;
use YAML qw(Dump LoadFile);

use base qw(
  App::CLI::Command
);

my $super = 'JiftyX::Fixtures::Script';

our $help_msg = qq{
Usage:

  jiftyx-fixtures scaffold [options]

Options:

  -e, --environment:        specify environment, default is development
  -h, --help:               show help
  --man                     man page

};

sub options {
  my ($self) = @_;
  (
    $super->options,
    'e|environment=s' => "environment",
  );
}

sub before_run {
  my ($self) = @_;

  $super->before_run($self);

  $self->{environment} ||= "development";

  return;
}

sub run {
  my ($self, $args) = @_;
  $self->before_run();

  Jifty->new;

  for my $env (keys %{$self->{config}->{fixtures}}) {

    my $dir = File::Spec->catfile(
      $self->{config}->{app_root},
      $self->{config}->{fixtures}->{$env}->{dir}
    );
    mkdir $dir unless (-e $dir);


    for my $model ($self->model_list) {
      my $filename = $self->fixtures_filename($env ,$model, "yml");
      my $file = IO::File->new ;
      if (defined $file->open("> $filename") ) {
        print $file $self->render_scaffold(Jifty->app_class("Model",$model)->columns);
        $file->close;
      }
    }

  }

}

sub render_scaffold {
  my ($self, @columns) = @_;
  my $result = "-\n";
  for (@columns) {
    $result .= "  " . $_->name . ":\n" if $_->{writable};
  }
  my $header = $result;
  $header =~ s/^/#/g;
  $header =~ s/\n/\n#/g;
  $header =~ s/#$//g;

  $header . $result;
}

sub model_list {
  my ($self) = @_;
  my @result =  map { basename($_) } glob(
    File::Spec->catfile(
      $self->{config}->{app_root},
      "lib",
      $self->{config}->{framework}->{ApplicationClass},
      "Model",
      "*"
    )
  );
  for (@result) {
    $_ =~ s/\.pm//g;
  }
  @result;
}

sub fixtures_filename {
  my ($self, $environment, $model, $format) = @_;
  return File::Spec->catfile(
      $self->{config}->{app_root},
      $self->{config}->{fixtures}->{$environment}->{dir},
      "$model.$format"
  );
}


1;

__END__
=head1 NAME

JiftyX::Fixtures::Script::Scaffold - scaffold subcommands

=head1 VERSION

version 0.07

=head1 AUTHOR

  shelling <shelling@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by <shelling@cpan.org>.

This is free software, licensed under:

  The MIT (X11) License


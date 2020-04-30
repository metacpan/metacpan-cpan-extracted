package Devel::MojoProf;
use Mojo::Base -base;

use Class::Method::Modifiers 'install_modifier';
use Devel::MojoProf::Reporter;
use Mojo::Loader 'load_class';
use Scalar::Util 'blessed';
use Time::HiRes qw(gettimeofday tv_interval);

use constant CALLER => $ENV{DEVEL_MOJOPROF_CALLER} // 1;

our $VERSION = '0.04';

# Required for "perl -d:MojoProf ..."
DB->can('DB') or *DB::DB = sub { };

sub add_profiling_for {
  my $params = ref $_[-1] eq 'HASH' ? pop : {};
  my $self   = _instance(shift);
  return $self->tap($self->can("_add_profiling_for_$_[0]")) if @_ == 1;

  return unless my $target = $self->_ensure_loaded(shift);
  while (my $method = shift) {
    next if $self->{installed}{$target}{$method}++;
    $self->_add_profiling_for_method($target, $method, ref $_[0] ? shift : undef, $params);
  }

  return $self;
}

sub import {
  my $class = shift;
  my @flags = @_ ? @_ : qw(-mysql -pg -redis -sqlite -ua);

  $class->add_profiling_for($_) for map { s!^-!!; $_ } @flags;
}

sub new {
  my $self = shift->SUPER::new(@_);
  $self->reporter($self->{reporter} || Devel::MojoProf::Reporter->new);
  $self;
}

sub reporter {
  my $self = shift;
  return $self->{reporter} unless @_;
  $self->{reporter} = blessed $_[0] ? $_[0] : Devel::MojoProf::Reporter->new->handler($_[0]);
  return $self;
}

sub singleton { state $self = __PACKAGE__->new }

sub _add_profiling_for_method {
  my ($self, $target, $method, $make_message, $params) = @_;

  my %params = (ignore_caller => qr{^$target}, %$params);
  $make_message ||= sub { shift; join ' ', @_ };

  install_modifier $target => around => $method => sub {
    my ($orig, @args) = @_;
    my $wantarray = wantarray;
    my %report    = (class => $target, method => $method);

    _add_caller_to_report(\%params, \%report) if CALLER;

    my $cb = ref $args[-1] eq 'CODE' ? pop @args : undef;
    push @args, sub { $self->_report_for(\%report, $make_message->(@args)); $cb->(@_) }
      if $cb;

    $report{t0} = [gettimeofday];
    my @res = $wantarray ? $orig->(@args) : (scalar $orig->(@args));

    if ($cb) {
      1;    # do nothing
    }
    elsif (blessed $res[0] and $res[0]->isa('Mojo::Promise')) {
      $res[0]->finally($self->_report_for(\%report, $make_message->(@args)));
    }
    else {
      $self->_report_for(\%report, $make_message->(@args));
    }

    return $wantarray ? @res : $res[0];
  };
}

sub _add_caller_to_report {
  my ($params, $report) = @_;

  my $i = 0;
  while (my @caller = caller($i++)) {
    next if $caller[0] eq 'Devel::MojoProf' or $caller[0] =~ $params->{ignore_caller};
    @$report{qw(file line)} = @caller[1, 2];
    last;
  }
}

sub _add_profiling_for_pg {
  my $self = shift;
  $self->add_profiling_for('Mojo::Pg::Database', query => \&_make_desc_for_db, query_p => \&_make_desc_for_db)
    if $self->_ensure_loaded('Mojo::Pg', 1);
}

sub _add_profiling_for_mysql {
  my $self = shift;
  $self->add_profiling_for('Mojo::mysql::Database', query => \&_make_desc_for_db, query_p => \&_make_desc_for_db)
    if $self->_ensure_loaded('Mojo::mysql', 1);
}

sub _add_profiling_for_redis {
  my $self = shift;
  $self->add_profiling_for('Mojo::Redis::Connection', 'write_p', {ignore_caller => qr{^Mojo::Redis}})
    if $self->_ensure_loaded('Mojo::Redis', 1);
}

sub _add_profiling_for_sqlite {
  my $self = shift;
  $self->add_profiling_for('Mojo::SQLite::Database', query => \&_make_desc_for_db)
    if $self->_ensure_loaded('Mojo::SQLite', 1);
}

sub _add_profiling_for_ua {
  shift->add_profiling_for('Mojo::UserAgent', start => \&_make_desc_for_ua);
}

sub _ensure_loaded {
  my ($self, $target, $no_warn) = @_;
  return $target unless my $e = load_class $target;
  die "[Devel::MojoProf] Could not load $target: $e" if ref $e;
  warn "[Devel::MojoProf] Could not find module $target\n" unless $no_warn;
  return;
}

sub _instance { ref $_[0] ? $_[0] : shift->singleton }

sub _make_desc_for_db { $_[1] }
sub _make_desc_for_ua { sprintf '%s %s', $_[1]->req->method, $_[1]->req->url->to_abs }

sub _report_for {
  my ($self, $report, $message) = @_;
  @$report{qw(elapsed message)} = (tv_interval($report->{t0}), $message);
  $self->{reporter}->report($report, $self);
}

1;

=encoding utf8

=head1 NAME

Devel::MojoProf - Profile blocking, non-blocking a promise based Mojolicious APIs

=head1 SYNOPSIS

  $ perl -d:MojoProf myapp.pl
  $ perl -d:MojoProf -e'Mojo::UserAgent->new->get("https://mojolicious.org")'
  $ DEVEL_MOJOPROF_OUT_CSV=1 perl -d:MojoProf myapp.pl

See L<Devel::MojoProf::Reporter/out_csv> for how C<DEVEL_MOJOPROF_OUT_CSV> works.

=head1 DESCRIPTION

L<Devel::MojoProf> can add profiling output for blocking, non-blocking and
promise based methods. It can be customized to log however you want, but the
default is to print a line like the one below to STDERR:

  0.00038ms [Mojo::Pg::Database::query_p] SELECT 1 as whatever at path/to/app.pl line 23

=head1 ATTRIBUTES

=head2 reporter

  my $obj  = $prof->reporter;
  my $prof = $prof->reporter($reporter_class->new);

Holds a reporter object that is capable of creating reports by the measurements
done by C<$prof>. Holds by default an instance of L<Devel::MojoProf::Reporter>.

=head1 METHODS

=head2 add_profiling_for

  my $prof = $prof->add_profiling_for($moniker);
  my $prof = $prof->add_profiling_for($class => $method1, $method2, ...);
  my $prof = $prof->add_profiling_for($class => $method1 => $make_message, ...);
  my $prof = $prof->add_profiling_for($class => $method1 => $make_message, ..., \%params);
  my $prof = $prof->add_profiling_for($class => $method1 => $make_message, ..., \%params);
  my $prof = Devel::MojoProf->add_profiling_for(...);

Used to add profiling for either a C<$moniker> (short module identifier) or a
class and method. This method can also be called as a class method.

The supported C<$moniker> are for now "mysql", "pg", "redis", "sqlite" and
"ua". See L</import> for more details.

It is also possible to manually add support for other custom modules. Here is
an example:

  $prof->add_profiling_for("My::Cool::Class", "get_stuff" => sub {
    my ($my_cool_obj, @args) = @_;
    return "This will be the 'message' part in the report";
  });

The CODE ref passed in will get all the arguments that the C<get_suff()> method
gets, and the return value should be a string that becomes the C<message> part
in the C<$report> hash-ref passed to the L</reporter>.

C<%params> is optional and can have the following keys:

=over 2

=item * ignore_caller

Defaults to a regex holding the C<$class>, but can set to any class that you
want to skip to generate the C<class> key for the L</reporter> method.

=back

=head2 import

  use Devel::MojoProf (); # disable auto-detect
  use Devel::MojoProf;    # All of the modules from the list below
  use Devel::MojoProf -mysql;
  use Devel::MojoProf -pg;
  use Devel::MojoProf -redis;
  use Devel::MojoProf -sqlite;
  use Devel::MojoProf -ua;
  use Devel::MojoProf -pg, -redis, -ua; # Load multiple

Used to automatically L</add_profiling_for> know modules. Currently supported
modules are L<Mojo::mysql>, L<Mojo::Pg>, L<Mojo::Redis>, L<Mojo::SQLite> and
L<Mojo::UserAgent>.

Please submit a PR or create an issue if you think more modules should be
supported at L<https://github.com/jhthorsen/devel-mojoprof>.

=head2 singleton

  my $prof = Devel::MojoProf->singleton;

Used to retrive the singleton object that is used by L</add_profiling_for> when
called as a class method.

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018, Jan Henning Thorsen.

This program is free software, you can redistribute it and/or modify it
under the terms of the Artistic License version 2.0.

=head1 SEE ALSO

This module is inspired by L<Devel::KYTProf>.

=cut

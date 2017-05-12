{
  package Filter::Include;

  $VERSION  = '1.7';

  use strict;
  # XXX - this is dropped for the sake of pre-5.6 perls
  # use warnings;

  use Carp 'croak';
  use Scalar::Util 'reftype';
  use File::Spec::Functions 'catfile';
  use Module::Locate Global => 1, 'get_source';

  use vars '$MATCH_RE';
  $MATCH_RE = qr{ ^ \043 ? \s* include \s+ (.+?) ;? $ }xm;

  sub install_handler {
    my($name, $handler) = @_;

    croak "The $name handler must be a CODE reference, was given: " .
          ref($handler) || $handler
      if !ref $handler or reftype $handler ne 'CODE';

    no strict 'refs';
    *{$name . '_handler'} = $handler;
  }

  sub import {
    my( $called_by, %args ) = @_;

    install_handler $_ => delete $args{$_}
      for grep exists $args{$_}, qw/ before after pre post /;
  }

  ## There's probably a nice module to do this somewhere ...
  sub handler {
    my $name    = shift(@_) . '_handler';
    my $handler = \&$name;

    goto &$handler
      if defined &$name;
  }

  use vars '$LINE';
  sub _filter {
    local $_ = shift;

    s{$MATCH_RE}{
      my $include = $1;

      ## Only do this the first time.
      $LINE = _find_initial_lineno($_, $&)
        unless defined $LINE;

      _source($include);
    }ge;

    $LINE += tr[\n][\n];

    return $_ . "\n#line $LINE\n";
  }

  ## work magic to find the first line number so #line declarations are correct
  sub _find_initial_lineno {
    my($src, $match) = @_;

    ## Find the number of lines before the $match in $src.
    my $include_at = () = substr($src, 0, index($src, $match)) =~ /^(.?)/mg;

    my($i, $called_from) = 0;
    $called_from = ( caller $i++ )[2]
      while caller $i;

    ## We need the caller's line num in addition to the number of lines before
    ## the match substring as Filter::Simple only filters after it is called.
    return $include_at + $called_from;
  }

  sub _resolve_source {
      my $include = shift;

      # Looks like a package so treat it like one.
      return $include, get_source($include)
        if $include =~ $Module::Locate::PkgRe;

      # Probably got a string so attempt to get a path.
      local $@;
      my $path = eval $include;

      croak "Filter::Include - failed to resolve filename from '$path' - $@"
        if $@;

      open my $fh, '<', $path
        or croak "Filter::Include - couldn't open '$path' for reading - $!";

      local $/;
      return $path, <$fh>;
  }

  sub _source {
    my $source = shift;

    return ''
      unless defined $source;

    my($include, $data) = _resolve_source($source);

    $data = _expand_source($include, $data);

    return $data;
  }

  sub _expand_source {
    my($include, $data) = @_;

    handler pre => $include, $data;

    $data = _filter($data)
      if $data =~ $MATCH_RE;

    handler post => $include, $data;

    return $data;
  }

  use Filter::Simple;
  FILTER {
    ## You are crazy Filter::Simple, quite simply mad.
    return
      if /\A\s*\z/s;

    handler before => $_;
    $_ = _filter($_);
    handler after => $_;
  };
}

q. The End.;

=pod

=head1 NAME

Filter::Include - Emulate the behaviour of the C<#include> directive

=head1 SYNOPSIS

  use Filter::Include;

  include Foo::Bar;
  include "somefile.pl";

  ## or the C preprocessor directive style:

  #include Some::Class
  #include "little/library.pl"

=head1 DESCRIPTION

Take the C<#include> preproccesor directive from C<C>, stir in some C<perl>
semantics and we have this module. Only one keyword is used, C<include>, which
is really just a processor directive for the filter, which indicates the file to
be included. The argument supplied to C<include> will be handled like it would
by C<require> and C<use> so C<@INC> is searched accordingly and C<%INC> is
populated.

=head1 #include

For those who have not come across C<C>'s C<#include> preprocessor directive
this section shall explain briefly what it does.

When the C<C> preprocessor sees the C<#include> directive, it will include the
given file straight into the source. The file is dumped directly to where
C<#include> previously stood, so becomes part of the source of the given file
when it is compiled. This is used primarily for C<C>'s header files so function
and data predeclarations can be nicely separated out.

So given a small script like this:

  ## conf.pl
  my $conf = { lots => 'of', configuration => 'info' };

We can pull this file I<directly> in to the source of the following script
using C<Filter::Include>

  use Filter::Include;

  include 'conf.pl';
  print join(' ', map { $_, $conf->{$_} } reverse sort keys %$conf), "\n";

Once the filter is applied to the file above the source will look like this:

  ## conf.pl
  my $conf = { lots => 'of', configuration => 'info' };

  print join(' ', map { $_, $conf->{$_} } reverse sort keys %$conf), "\n";

So unlike C<perl>'s native file include functions C<Filter::Include> pulls the
source of the file to be included I<directly> into the caller's source without
any code evaluation.

=head2 Why not to use C<-P>

To quote directly from L<perlrun>:

  NOTE: Use of -P is strongly discouraged because of its inherent problems,
  including poor portability.

So while you can use the C<#include> natively in C<perl> it comes with the
baggage of the C<C> preprocessor.

=head1 HANDLERS

C<Filter::Include> has a facility to install handlers at various points of the
filtering process. These handlers can be installed by passing in the name of the
handler and an associated subroutine e.g

  use Filter::Include pre => sub {
                        my $include = shift;
                        print "Including $inc\n";
                      },
                      after => sub {
                        my $code = shift;
                        print "The resulting source looks like:\n$code\n";
                      };

This will install the C<pre> and C<after> handlers (documented below).

These handlers are going to be most suited for debugging purposes but could also
be useful for tracking module usage.

=over 4

=item pre/post

Both handlers take two positional arguments - the current include e.g
C<library.pl> or C<Legacy::Code>, and the source of the include which in the
case of the C<pre> handler is the source before it is parsed and in the case of
the C<post> handler it is the source after it has been parsed and updated as
appropriate.

=item before/after

Both handlers take a single argument - a string representing the relevant
source code. The C<before> handler is called I<before> any filtering is
performed so it will get the pre-filtered source as its first argument. The
C<after> handler is called I<after> the filtering has been performed so will
get the source post-filtered as its first argument.

=back

=head1 AUTHOR

Dan Brook C<< <cpan@broquaint.com> >>

=head1 SEE ALSO

C<C>, -P in L<perlrun>, L<Filter::Simple>, L<Filter::Macro>

=cut

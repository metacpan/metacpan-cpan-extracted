package HTML::MasonX::Free::Resolver 0.007;

# ABSTRACT: a resolver that lets you specialize components with dir overlays
use Moose;

#pod =head1 OVERVIEW
#pod
#pod This class is a replacement for L<HTML::Mason::Resolver::File>.  If you don't
#pod know anything about what the resolver does or what comp roots are, this whole
#pod thing might make no sense.  If you really like L<Mason|HTML::Mason>, though, it
#pod might be worth reading about it.  Right now.
#pod
#pod Okay, are you caught up?
#pod
#pod The next thing you need to keep in mind is that the C<comp_roots> parameter is
#pod part of the I<interp> and not part of the I<resolver>.  Does this seem weird to
#pod you?  Me too, but that's how it is.
#pod
#pod So, let's say you had this set of C<comp_roots>:
#pod
#pod   my_app  =>  /usr/myapp/mason
#pod   shared  =>  /usr/share/mason
#pod
#pod The idea is that you can have stuff in the C<my_app> root that specializes
#pod generalized stuff in the C<shared> root.  Unfortunately, it's not really very
#pod useful.  You can't have F<foo> in the first comp root inherit from F<foo> in
#pod the second.  You can't easily take an existing set of templates and specialize
#pod them with an overlay.
#pod
#pod I<That> is the problem that this resolver is meant to solve.  Instead of having
#pod the resolver try to find each path in each comp root independenly, the
#pod C<comp_roots> are instead stored in the resolver's C<resolver_roots>.  When
#pod looking for a path, it looks in each root in turn.  When it finds one, it
#pod returns that.  If there's another one in one of the later paths, the one that
#pod was found will automatically be made to inherit from it and (by default) to
#pod call it by default.
#pod
#pod Because you don't want the interp object to confuse things with comp roots, you
#pod must signal that you know that its comp roots will be ignored by setting
#pod C<comp_root> to "C</->".
#pod
#pod Say you set up your resolver roots like this:
#pod
#pod   my_app  => /usr/myapp/mason
#pod   shared  => /usr/share/mason
#pod
#pod Then you have these two files:
#pod
#pod B<F</usr/share/mason/welcome>>:
#pod
#pod   <h1>Welcome to <& SELF:site &>, <& SELF:user &>!</h1>
#pod   <%method site>the site</%method>
#pod   <%method user><% $m->user->name |h %></%method>
#pod
#pod B<F</usr/myapp/mason>>:
#pod
#pod   <%method site>my guestbook</%method>
#pod
#pod If you resolve and render F</welcome>, it will say:
#pod
#pod   Welcome to my guestbook, User Name.
#pod
#pod If you absolutely must render the shared welcome component directly, you can
#pod refer to F</shared=/welcome>.
#pod
#pod This is pretty experimental code.  It also probably doesn't work with some
#pod Mason options that I don't use, like preloading, because I haven't implemented
#pod the C<glob_path> method.
#pod
#pod =attr comp_class
#pod
#pod This argument is the class that will be used for components created by this
#pod resolver.  The default is HTML::Mason::Component::FileBased.
#pod
#pod Because HTML::MasonX::Resolver::AutoInherit is not (right now) part of
#pod Class::Container, you can't pass this as an argument to the interp constructor.
#pod
#pod =cut

use Carp qw(carp cluck croak);
use HTML::Mason::Tools qw(read_file_ref);
use List::AllUtils 'max';

use namespace::autoclean;

sub isa {
  my ($self, $class) = @_;
  return 1 if $class eq 'HTML::Mason::Resolver';
  return $self->SUPER::isa($class);
}

sub glob_path { croak "unimplemented; $_[0] cannot preload" }

# [ [ foo => $path1 ], [ bar => $path2 ] ]
# This is really anemic validation.
has resolver_roots => (
  isa => 'ArrayRef',
  required => 1,
  traits   => [ 'Array' ],
  handles  => { resolver_roots => 'elements' },
);

has allow_unusual_comp_roots => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

has add_next_call => (
  is  => 'ro',
  isa => 'Bool',
  default => 1,
);

has comp_class => (
  is  => 'ro',
  isa => 'Str',
  default => 'HTML::Mason::Component::FileBased',
);


sub get_info {
  my ($self, $given_path, $comp_root_key, $comp_root_path) = @_;

  # It's unfortunate that comp roots are a property of the interpreter and not
  # the resolver. -- rjbs, 2012-09-19
  if (
    ! $self->allow_unusual_comp_roots
    and ($comp_root_key ne 'MAIN' or $comp_root_path !~ m{\A[\\/]-\z})
  ) {
    croak "when using HTML::MasonX::Free::Resolver, you must either "
        . "set the comp_root to '/-' or set allow_unusual_comp_roots to true";
  }

  my ($want_root, $path);

  if ($given_path =~ /=/) { ($want_root, $path) = split /=/, $given_path;
                            $want_root =~ s{^/}{};                        }
  else                    { ($want_root, $path) = (undef, $given_path)    }

  my $saw_me;
  my @seen_in;
  for my $root ($self->resolver_roots) {
    my ($root_name, $root_path) = @$root;
    next if $want_root and ! $saw_me and $want_root ne $root_name;
    $saw_me = 1;

    my $fn = File::Spec->canonpath( File::Spec->catfile($root_path, $path) );

    push @seen_in, [ $root_name, $fn ] if -e $fn;
  }

  return unless @seen_in;

  my $modified = (stat $seen_in[0][1])[9];

  my $base = $comp_root_key eq 'MAIN' ? '' : "/$comp_root_key";
  $comp_root_key = undef if $comp_root_key eq 'MAIN';

  my $srcfile = $seen_in[0][1];
  return unless -f $srcfile;

  return HTML::Mason::ComponentSource->new(
    friendly_name => $srcfile,
    comp_id       => "$base:$seen_in[0][0]=$seen_in[0][1]",
    last_modified => $modified,
    comp_path     => $given_path,
    comp_class    => $self->comp_class,
    extra         => { comp_root => $comp_root_key },
    source_callback => sub {
      my $body .= ${ read_file_ref($srcfile) };
      if (@seen_in > 1) {
        $body = qq{<%flags>inherit => "/$seen_in[1][0]=$path"</%flags>}
              . $body . "\n"
              . ($self->add_next_call ? "% \$m->call_next if \$m->fetch_next;\n"
                                      : '');
      }

      \$body;
    },
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::MasonX::Free::Resolver - a resolver that lets you specialize components with dir overlays

=head1 VERSION

version 0.007

=head1 OVERVIEW

This class is a replacement for L<HTML::Mason::Resolver::File>.  If you don't
know anything about what the resolver does or what comp roots are, this whole
thing might make no sense.  If you really like L<Mason|HTML::Mason>, though, it
might be worth reading about it.  Right now.

Okay, are you caught up?

The next thing you need to keep in mind is that the C<comp_roots> parameter is
part of the I<interp> and not part of the I<resolver>.  Does this seem weird to
you?  Me too, but that's how it is.

So, let's say you had this set of C<comp_roots>:

  my_app  =>  /usr/myapp/mason
  shared  =>  /usr/share/mason

The idea is that you can have stuff in the C<my_app> root that specializes
generalized stuff in the C<shared> root.  Unfortunately, it's not really very
useful.  You can't have F<foo> in the first comp root inherit from F<foo> in
the second.  You can't easily take an existing set of templates and specialize
them with an overlay.

I<That> is the problem that this resolver is meant to solve.  Instead of having
the resolver try to find each path in each comp root independenly, the
C<comp_roots> are instead stored in the resolver's C<resolver_roots>.  When
looking for a path, it looks in each root in turn.  When it finds one, it
returns that.  If there's another one in one of the later paths, the one that
was found will automatically be made to inherit from it and (by default) to
call it by default.

Because you don't want the interp object to confuse things with comp roots, you
must signal that you know that its comp roots will be ignored by setting
C<comp_root> to "C</->".

Say you set up your resolver roots like this:

  my_app  => /usr/myapp/mason
  shared  => /usr/share/mason

Then you have these two files:

B<F</usr/share/mason/welcome>>:

  <h1>Welcome to <& SELF:site &>, <& SELF:user &>!</h1>
  <%method site>the site</%method>
  <%method user><% $m->user->name |h %></%method>

B<F</usr/myapp/mason>>:

  <%method site>my guestbook</%method>

If you resolve and render F</welcome>, it will say:

  Welcome to my guestbook, User Name.

If you absolutely must render the shared welcome component directly, you can
refer to F</shared=/welcome>.

This is pretty experimental code.  It also probably doesn't work with some
Mason options that I don't use, like preloading, because I haven't implemented
the C<glob_path> method.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 ATTRIBUTES

=head2 comp_class

This argument is the class that will be used for components created by this
resolver.  The default is HTML::Mason::Component::FileBased.

Because HTML::MasonX::Resolver::AutoInherit is not (right now) part of
Class::Container, you can't pass this as an argument to the interp constructor.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

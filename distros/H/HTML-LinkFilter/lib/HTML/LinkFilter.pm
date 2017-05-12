package HTML::LinkFilter;
use strict;
use warnings;
use HTML::Parser;

our $VERSION = "0.03";

## The html tags which might have URLs
# the master list of tagolas and required attributes (to constitute a link)
our %TAGS = ( # Copied from HTML::LinkExtractor 0.13
              a => [qw( href )],
         applet => [qw( archive code codebase src )],
           area => [qw( href )],
           base => [qw( href )],
        bgsound => [qw( src )],
     blockquote => [qw( cite )],
           body => [qw( background )],
            del => [qw( cite )],
            div => [qw( src )], # IE likes it, but don't know where it's documented
          embed => [qw( pluginspage pluginurl src )],
           form => [qw( action )],
          frame => [qw( src longdesc  )],
         iframe => [qw( src )],
         ilayer => [qw( background src )],
            img => [qw( dynsrc longdesc lowsrc src usemap )],
          input => [qw( dynsrc lowsrc src )],
            ins => [qw( cite )],
        isindex => [qw( action )], # real oddball
          layer => [qw( src )],
           link => [qw( src href )],
         object => [qw( archive classid code codebase data usemap )],
              q => [qw( cite )],
         script => [qw( src  )], # HTML::Tagset has 'for' ~ it's WRONG!
          sound => [qw( src )],
          table => [qw( background )],
             td => [qw( background )],
             th => [qw( background )],
             tr => [qw( background )],
  ## the exotic cases
           meta => undef,
     '!doctype' => [qw( url )], # is really a process instruction
);

### HTML::Parser method, not for __PACKAGE__.
my $default_h_sub = sub {
    my( $self, $tagname, $original ) = @_;

    push @{ $self->{link_filter}{tags} }, $original;

    return;
};

### HTML::Parser method, not for __PACKAGE__.
my $start_h_sub = sub {
    my( $self, $tagname, $attr_ref, $original ) = @_;

    unless ( exists $TAGS{ $tagname } ) {
        push @{ $self->{link_filter}{tags} }, $original
            and return;
    }

    unless ( grep { my $name = $_; grep { $_ eq $name } @{ $TAGS{ $tagname } } } keys %{ $attr_ref } ) {
        push @{ $self->{link_filter}{tags} }, $original
            and return;
    }

    unless ( $self->{link_filter}{cb} ) {
        push @{ $self->{link_filter}{tags} }, $original
            and return;
    }

    foreach my $attr ( keys %{ $attr_ref } ) {
        next
            unless grep { $_ eq $attr } @{ $TAGS{ $tagname } };

        my $new = $self->{link_filter}{cb}->(
            $tagname, $attr, $attr_ref->{ $attr }, $attr_ref,
        );

        $attr_ref->{ $attr } = $new
            if defined $new;
    }

    my $tag = do {
        my $build    = q{};
        my $is_xhtml = grep { $_ eq q{/} } keys %{ $attr_ref };
        my $attr     = join q{ }, map {
            join q{=}, $_, join q{}, q{"}, $attr_ref->{ $_ }, q{"},
        } grep { $_ ne q{/} } sort keys %{ $attr_ref };

        if ( $attr && $is_xhtml ) {
            $build = "<$tagname $attr />";
        }
        elsif ( $attr && ! $is_xhtml ) {
            $build = "<$tagname $attr>";
        }
        elsif ( ! $attr && $is_xhtml ) {
            $build = "<$tagname />";
        }
        else {
            $build = "<$tagname>";
        }

        if ( chomp $original ) {
            $build .= "\n";
        }

        $build;
    };

    push @{ $self->{link_filter}{tags} }, $tag;

    return $self;
};

sub new {
    my $class = shift;
    my %param = @_;

    my $self = bless \%param, $class;

    my $p = HTML::Parser->new(
        api_version => 3,
        start_h   => [
            $start_h_sub,   "self, tagname, attr, text",
        ],
        default_h => [
            $default_h_sub, "self, tagname, text",
        ],
    );

    $p->{link_filter} = $self;
    $self->{p}        = $p;
    $self->_init_tags;

    return $self;
}

sub change {
    my $self = shift;
    my( $html, $callback_sub ) = @_;

    $self->_init_tags;
    $self->{cb} = $callback_sub;
    $self->{p}->parse( $html );
    $self->{p}->eof;

    return $self;
}

sub _init_tags {
    my $self = shift;
    $self->{tags} = [ ];
    return $self;
}

sub tags {
    return shift->{tags};
}

sub html {
    my $self = shift;

    return join q{}, @{ $self->tags };
}

1;
__END__

=head1 NAME

HTML::LinkFilter - Changes all links in HTML

=head1 SYNOPSIS

  use HTML::LinkFilter;
  use Data::Dumper;

  my $html = do { local $/; <DATA> };

  my $filter = HTML::LinkFilter->new;
  $filter->change( \$html, \&callback );

  print Dumper $filter->tags;

  sub callback {
      my( $tagname, $attr, $value ) = @_;

      return; # Uses original.
  }

  __DATA__
  <!doctype html>
  <html>
    <head>
      <meta charset="UTF-8" />
    </head>
    <body>
      <h1><a href="/">example.com</a></h1>
    </body>
  </html>

=head1 DESCRIPTION

HTML::LinkFilter can change all links in passed HTML.

This requires callback sub.  The sub takes tagname, attr, value,
and returns new value, then it will be replaced. Or uses original
when returns undef.

*Note* this breaks attributes order in tag.

=head1 METHODS

=over

=item new

Returns instance.

=item change

Changes html to tags by using callback filter.
Callback filter is an argument which changes link.

Callback filter will take args those are tagname, attr, value,
and return value is pushed to $self->tags as a new value.

Callback filter can tell 'use original' to parser by returns undef.

=item tags

Returns some changed HTML tags.

=item html

Returns HTML code which is parsed.

=back

=head1 AUTHOR

kuniyoshi kouji E<lt>kuniyoshi@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


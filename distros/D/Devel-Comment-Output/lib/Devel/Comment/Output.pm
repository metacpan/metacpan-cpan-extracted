package Devel::Comment::Output;
use strict;
use warnings;
use 5.008_001;
use Symbol ();
use Scalar::Util qw(refaddr);

our $VERSION = '0.02';

our $Prefix = $ENV{DEVEL_COMMENT_OUTPUT_PREFIX} || '=> ';
our %Instances;

sub import {
    my ($class, %args) = @_;

    my (undef, $file, undef) = caller;

    my $self = $class->new(
        handle => \*STDOUT,
        file   => $file,
        prefix => $Prefix,
        inline => 1,
        %args,
    );
    $self->setup;
}

sub new {
    my ($class, %args) = @_;
    $args{results} = {};
    return bless \%args, $class;
}

sub setup {
    my $self = shift;

    my $symbol = Symbol::gensym();
    my $handle = tie *$symbol, 'Devel::Comment::Output::Handle';

    open $self->{original_handle}, '>&', $self->{handle} or die $!;

    *{$self->{handle}} = $symbol;

    $Instances{ refaddr $handle } = $self;

    return $self;
}

sub from_handle {
    my ($class, $handle) = @_;
    return $Instances{ refaddr $handle };
}

sub write {
    my $self = shift;
    my $class = ref $self;

    local *{$self->{handle}};
    local $/ = "\n";

    my @in = do {
        open my $in, '<', $self->{file} or die $!;
        <$in>;
    };

    my @out;
    for my $i (0 .. $#in) {
        $in[$i] =~ s/^(use \Q$class\E\b)/# $1/;

        my @results = split /\n/, join '', @{ $self->{results}->{$i+1} || [] };
        if (@results == 1 && $self->{inline}) {
            $in[$i] =~ s/$/ # $self->{prefix}$results[0]/;
            push @out, $in[$i];
        } else {
            push @out, $in[$i], map { "# $_\n" } @results;
        }
    }

    open my $out, '>', $self->{file};
    print $out join '', @out;

    $self->{wrote}++;
}

sub DESTROY {
    my $self = shift;
    $self->write unless $self->{wrote};
}

package
    Devel::Comment::Output::Handle;
use Tie::Handle;
use parent -norequire => 'Tie::StdHandle';

sub PRINT {
    my ($self, @args) = @_;

    no warnings;

    my $dco = Devel::Comment::Output->from_handle($self);
    print { $dco->{original_handle} } @args;

    foreach (@args) {
        utf8::encode($_) if utf8::is_utf8($_);
    }

    my $depth = 0;
    while (my ($pkg, $file, $line) = caller($depth++)) {
        if ($file eq $dco->{file}) {
            push @{ $dco->{results}->{$line} ||= [] }, @args;
            return;
        }
    }
}

sub PRINTF {
    my $self = shift;
    my $format = shift;
    @_ = ( $self, sprintf $format, @_ );
    goto \&PRINT;
}

1;

__END__

=head1 NAME

Devel::Comment::Output - Comment program output to your script after execution

=head1 SYNOPSIS

Write your script:

  use Devel::Comment::Output;
  use Data::Dumper;

  print 1 + 2;
  print Dumper { a => 1 };

after running, comments are added to the script like:

  # use Devel::Comment::Output;
  use Data::Dumper;

  print 1 + 2; # => 3;
  print Dumper { a => 1 };
  # $VAR1 = {
  #           'a' => 1
  #         };

=head1 DESCRIPTION

Devel::Comment::Output captures script outputs and
embeds the outputs to the script.

=head1 OPTIONS

  use Devel::Comment::Output;

is equivalent to below:

  use Devel::Comment::Output (
      handle => \*STDOUT, # Handle to capture
      file => __FILE__,   # File to rewrite
      inline => 1,        # Allow inline comment
      prefix => '=> '     # Inline comment prefix
  );

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

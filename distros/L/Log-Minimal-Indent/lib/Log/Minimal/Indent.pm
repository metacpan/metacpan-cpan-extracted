package Log::Minimal::Indent;
use 5.010000;
use strict;
use warnings;

our $VERSION = "0.01";

use Log::Minimal;
use Guard;


our $PADDING = "  ";

our @EXPORT_OK = qw/indent_log_guard indent_log_scope/;
our @EXPORT = @EXPORT_OK;

sub import {
    my $class   = shift;
    my $package = caller(0);
    
    @_ = @EXPORT  unless @_;
    
    my (@export, @args);
    my $re_export_ok = qr/^(?:@{[ join '|', @EXPORT_OK ]})$/;
    foreach ( @_ ) {
        if ( /$re_export_ok/ ) {
            push @export, $_;
        } else {
            push @args, $_;
        }
    }
    
    no strict 'refs';
    foreach my $f ( @export ) {
        *{"$package\::$f"} = \&$f;
    }
    
    @_ = ('Log::Minimal', @args);
    goto &Log::Minimal::import;
}


my $indent_level = 0;

sub forward {
    my ($class, $tag, $level) = @_;
    _level2coderef($level)->("<Entering $tag>");
    $indent_level++;
}

sub back {
    my ($class, $tag, $level) = @_;
    $indent_level--;
    _level2coderef($level)->("<Exited $tag>");
}

sub _level2coderef {
    local $_ = uc(shift // '');
    /^DEBUG$/     ? \&Log::Minimal::debugf :
    /^WARN$/      ? \&Log::Minimal::warnf  :
    /^CRITICAL$/  ? \&Log::Minimal::critf  :
    /^MUTE$/      ? \&_empty               :
    /^ERROR$/     ? \&Log::Minimal::croakf : \&Log::Minimal::infof;
}

sub _empty { }


{   # Overwrite Log::Minimal's behaviour
    my $orig_log = \&Log::Minimal::_log;
    no warnings 'redefine';
    *Log::Minimal::_log = sub{
        my $orig_PRINT = $Log::Minimal::PRINT;
        local $Log::Minimal::PRINT = sub{
            $orig_PRINT->(@_, $indent_level);
        };
        $orig_log->(@_);
    };
}

# Modify the default behaviour of PRINT and DIE
$Log::Minimal::PRINT = sub{
    my ( $time, $type, $message, $trace, $raw_message, $indent_level) = @_;
    my $indent = $PADDING x $indent_level;
    warn "$time $indent\[$type] $message at $trace\n";
};

$Log::Minimal::DIE = sub {
    my ( $time, $type, $message, $trace, $raw_message, $indent_level) = @_;
    my $indent = $PADDING x $indent_level;
    die "$time $indent\[$type] $message at $trace\n";
};


sub indent_log_guard {
    my @args = @_;
    __PACKAGE__->forward(@args);
    guard{ __PACKAGE__->back(@args) };
}

sub indent_log_scope {
    my @args = @_;
    __PACKAGE__->forward(@args);
    @_ = sub{ __PACKAGE__->back(@args) };
    goto &scope_guard;
}


1;
__END__

=encoding utf-8

=head1 NAME

Log::Minimal::Indent - Log::Minimal extension to support indentation

=head1 SYNOPSIS

  use Log::Minimal;
  use Log::Minimal::Indent;
  
  infof("Level zero");
  {
      indent_log_scope("foo");  # Indent forward one level in this block.
      warnf "Something to warn";
      {
          indent_log_scope("bar", "MUTE");  # You can mute enter/exit message.
          critf "Something critical happens!";
      }
      infof "Indent back here";
  }
  infof("Level zero again");
  
  # The above code prints like this:
  # 
  # 2013-09-23T11:39:19 [INFO] Level zero
  # 2013-09-23T11:39:19 [INFO] <Entering foo>
  # 2013-09-23T11:39:19   [WARN] Something to warn
  # 2013-09-23T11:39:19     [CRITICAL] Something critical happens!
  # 2013-09-23T11:39:19   [INFO] Indent back here
  # 2013-09-23T11:39:19 [INFO] <Exited foo>
  # 2013-09-23T11:39:19 [INFO] Level zero again
  
  # You can write the same program like this:
  use Log::Minimal::Indent;  # Actually, you don't need to use Log::Minimal,
                             # which automatically uses it for you.
  
  infof("Level zero");
  {
      my $g = indent_log_guard("foo");  # Indent one lovel as long as Guard object is alive.
      warnf "Something to warn";
      {
          my $h = indent_log_guard("bar", "MUTE");  # You can mute enter/exit message.
          critf "Something critical happens!";
      }
      infof "Indent back here";
  }
  infof("Level zero again");

=head1 DESCRIPTION

This module allows you to make indentation in logs output by Log::Minimal.

=head1 EXPORT FUNCTIONS

=head2 indent_log_scope($tag, $type)

=head2 indent_log_guard($tag, $type)

  indent_log_scope("tag", "INFO")
  my $guard = indent_log_guard("tag", "INFO")

C<indent_log_scope> indents log messages forward within a scope (block, subroutine, eval... etc),
then, indent back automatically when the execution exits from the scope.

C<indent_log_guard> works similarly, but it keeps forward-indent by the last reference to its
return-value (L<Guard> object) is gone.

=over 4

=item C<$tag:Str>

This is a kind of comment meaning what does this block is doing.
This string is used in the log message output by the functions like:

  [INFO] Entering <tag>
  ...
  [INFO] Exited <tag>

=item C<$type:Str> (default: "INFO")

Specifies which log level is used to output log message.
This argumment should be one of "DEBUG", "INFO", "WARN", "CRITICAL",
"MUTE" and "ERROR". The default value is "INFO".
You can disable log message by specifying "MUTE".

  indent_log_scope('bar', "MUTE");  # Does not output log messages.

=back

=head1 Manual Indentation

=head2 Log::Minimal::Indent->forward($tag, $type)

=head2 Log::Minimal::Indent->back($tag, $type)

If you really want to manage indentation by yourself, you can use these method to indent forward or back.

  Log::Minimal::Indent->forward("hoge");
      ...
          Log::Minimal::Indent->forward("fuga");
          ...
          Log::Minimal::Indent->back("fuga");
      ...
  Log::Minimal::Indent->back("hoge");

=head1 GLOBAL VARIABLE

=head2 $Log::Minimal::Indent::PADDING

Specifys prefixed-string to indent. Default to "  " (two white-spaces).

=head1 CUSTOMIZATION OF Log::Minimal

Log::Minimal::Indent modifies and overwrites a behaviour of Log::Minimal.
If you customize Log::Minimal with using $Log::Minimal::PRINT or $Log::Minimal::DIE,
read this section carefully.

Log::Minimal::Indent extends the parameter of $PRINT and $DIE as follows:

  $PRINT->($time, $type, $message, $trace,$raw_message, $indent_level);

They receive one additional parameter C<$indent_level>. This integer value shows
how deep indent level Log::Minimal::Indent is currently at. The other parameters
are passed as-is, including $raw_message. That is, you need to handle indentation
by yourself according to $indent_level when you use your own C<$PRINT> or C<$DIE>.

Log::Minimal::Indent overwrites C<$PRINT> and C<$DIE> the first time it is C<use>d 
or C<require>d to handle indentation.
Thus, you must C<use> this module before overriting C<$PRINT> or C<$DIE>.

=head1 LICENSE

Copyright (C) Daisuke (yet another) Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Daisuke (yet another) Maki E<lt>maki.daisuke AT gmail.comE<gt>

=cut


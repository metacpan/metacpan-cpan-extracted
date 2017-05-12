package Log::Log4perl::Tiny;

use strict;
use warnings;
{ our $VERSION = '1.4.0'; }

use Carp;
use POSIX ();

our ($TRACE, $DEBUG, $INFO, $WARN, $ERROR, $FATAL, $OFF, $DEAD);
my ($_instance, %name_of, %format_for, %id_for);
my $LOGDIE_MESSAGE_ON_STDERR = 1;

sub import {
   my ($exporter, @list) = @_;
   my ($caller, $file, $line) = caller();
   no strict 'refs';

   if (grep { $_ eq ':full_or_fake' } @list) {
      @list = grep { $_ ne ':full_or_fake' } @list;
      my $sue = 'use Log::Log4perl (@list)';
      eval "
         package $caller;
         $sue;
         1;
      " and return;
      unshift @list, ':fake';
   } ## end if (grep { $_ eq ':full_or_fake'...})

   my (%done, $level_set);
 ITEM:
   for my $item (@list) {
      next ITEM if $done{$item};
      $done{$item} = 1;
      if ($item =~ /^[a-zA-Z]/mxs) {
         *{$caller . '::' . $item} = \&{$exporter . '::' . $item};
      }
      elsif ($item eq ':levels') {
         for my $level (qw( TRACE DEBUG INFO WARN ERROR FATAL OFF DEAD )) {
            *{$caller . '::' . $level} = \${$exporter . '::' . $level};
         }
      }
      elsif ($item eq ':subs') {
         push @list, qw(
           ALWAYS TRACE DEBUG INFO WARN ERROR FATAL
           LOGWARN LOGDIE LOGEXIT LOGCARP LOGCLUCK LOGCROAK LOGCONFESS
           get_logger
         );
      } ## end elsif ($item eq ':subs')
      elsif ($item =~ /\A : (mimic | mask | fake) \z/mxs) {

         # module name as a string below to trick Module::ScanDeps
         if (!'Log::Log4perl'->can('easy_init')) {
            $INC{'Log/Log4perl.pm'} = __FILE__;
            *Log::Log4perl::import = sub { };
            *Log::Log4perl::easy_init = sub {
               my ($pack, $conf) = @_;
               if (ref $conf) {
                  $_instance = __PACKAGE__->new($conf);
                  $_instance->level($conf->{level})
                    if exists $conf->{level};
                  $_instance->format($conf->{format})
                    if exists $conf->{format};
                  $_instance->format($conf->{layout})
                    if exists $conf->{layout};
               } ## end if (ref $conf)
               elsif (defined $conf) {
                  $_instance->level($conf);
               }
            };
         } ## end if (!'Log::Log4perl'->...)
      } ## end elsif ($item =~ /\A : (mimic | mask | fake) \z/mxs)
      elsif ($item eq ':easy') {
         push @list, qw( :levels :subs :fake );
      }
      elsif (lc($item) eq ':dead_if_first') {
         get_logger()->_set_level_if_first($DEAD);
         $level_set = 1;
      }
      elsif (lc($item) eq ':no_extra_logdie_message') {
         $LOGDIE_MESSAGE_ON_STDERR = 0;
      }
   } ## end ITEM: for my $item (@list)

   if (!$level_set) {
      my $logger = get_logger();
      $logger->_set_level_if_first($INFO);
      $logger->level($logger->level());
   }

   return;
} ## end sub import

sub new {
   my $package = shift;
   my %args = ref($_[0]) ? %{$_[0]} : @_;

   $args{format} = $args{layout} if exists $args{layout};

   my $channels_input = [fh => \*STDERR];
   if (exists $args{channels}) {
      $channels_input = $args{channels};
   }
   else {
      for my $key (qw< file_append file_create file_insecure file fh >) {
         next unless exists $args{$key};
         $channels_input = [$key => $args{$key}];
         last;
      }
   } ## end else [ if (exists $args{channels...})]
   my $channels = build_channels($channels_input);
   $channels = $channels->[0] if @$channels == 1;    # remove outer shell

   my $self = bless {
      fh    => $channels,
      level => $INFO,
   }, $package;

   for my $accessor (qw( level fh format )) {
      next unless defined $args{$accessor};
      $self->$accessor($args{$accessor});
   }

   $self->format('[%d] [%5p] %m%n') unless exists $self->{format};

   if (exists $args{loglocal}) {
      my $local = $args{loglocal};
      $self->loglocal($_, $local->{$_}) for keys %$local;
   }

   return $self;
} ## end sub new

sub build_channels {
   my @pairs = (@_ && ref($_[0])) ? @{$_[0]} : @_;
   my @channels;
   while (@pairs) {
      my ($key, $value) = splice @pairs, 0, 2;

      # some initial validation
      croak "build_channels(): undefined key in list"
        unless defined $key;
      croak "build_channels(): undefined value for key $key"
        unless defined $value;

      # analyze the key-value pair and set the channel accordingly
      my ($channel, $set_autoflush);
      if ($key =~ m{\A(?: fh | sub | code | channel )\z}mxs) {
         $channel = $value;
      }
      elsif ($key eq 'file_append') {
         open $channel, '>>', $value
           or croak "open('$value') for appending: $!";
         $set_autoflush = 1;
      }
      elsif ($key eq 'file_create') {
         open $channel, '>', $value
           or croak "open('$value') for creating: $!";
         $set_autoflush = 1;
      }
      elsif ($key =~ m{\A file (?: _insecure )? \z}mxs) {
         open $channel, $value
           or croak "open('$value'): $!";
         $set_autoflush = 1;
      }
      else {
         croak "unsupported channel key '$key'";
      }

      # autoflush new filehandle if applicable
      if ($set_autoflush) {
         my $previous = select($channel);
         $|++;
         select($previous);
      }

      # record the channel, on to the next
      push @channels, $channel;
   } ## end while (@pairs)
   return \@channels;
} ## end sub build_channels

sub get_logger { return $_instance ||= __PACKAGE__->new(); }
sub LOGLEVEL { return get_logger()->level(@_); }

sub LEVELID_FOR {
   my $level = shift;
   return $id_for{$level} if exists $id_for{$level};
   return;
} ## end sub LEVELID_FOR

sub LEVELNAME_FOR {
   my $id = shift;
   return $name_of{$id} if exists $name_of{$id};
   return $id if exists $id_for{$id};
   return;
} ## end sub LEVELNAME_FOR

sub loglocal {
   my $self   = shift;
   my $key    = shift;
   my $retval = delete $self->{loglocal}{$key};
   $self->{loglocal}{$key} = shift if @_;
   return $retval;
} ## end sub loglocal
sub LOGLOCAL { return get_logger->loglocal(@_) }

sub format {
   my $self = shift;

   if (@_) {
      $self->{format} = shift;
      $self->{args}   = \my @args;
      my $replace = sub {
         if (defined $_[2]) {    # op with options
            my ($num, $opts, $op) = @_[0 .. 2];
            push @args, [$op, $opts];
            return "%$num$format_for{$op}[0]";
         }
         if (defined $_[4]) {    # op without options
            my ($num, $op) = @_[3, 4];
            push @args, [$op];
            return "%$num$format_for{$op}[0]";
         }

         # not an op
         my $char = ((!defined($_[5])) || ($_[5] eq '%')) ? '' : $_[5];
         return '%%' . $char;    # keep the percent AND the char, if any
      };

      # transform into real format
      my ($with_options, $standalone) = ('', '');
      for my $key (keys %format_for) {
         my $type = $format_for{$key}[2] || '';
         $with_options .= $key if $type;
         $standalone   .= $key if $type ne 'required';
      }

      # quotemeta or land on impossible character class if empty
      $_ = length($_) ? quotemeta($_) : '^\\w\\W'
        for ($with_options, $standalone);
      $self->{format} =~ s<
            %                      # format marker
            (?:
                  (?:                       # something with options
                     ( -? \d* (?:\.\d+)? )  # number
                     ( (?:\{ .*? \}) )      # options
                     ([$with_options])     # specifier
                  )
               |  (?:
                     ( -? \d* (?:\.\d+)? )  # number
                     ([$standalone])        # specifier
                  )
               |  (.)                       # just any char
               |  \z                        # just the end of it!
            )
         >
         {
            $replace->($1, $2, $3, $4, $5, $6);
         }gsmex;
   } ## end if (@_)
   return $self->{format};
} ## end sub format

*layout = \&format;

sub emit_log {
   my ($self, $message) = @_;
   my $fh = $self->{fh};
   for my $channel ((ref($fh) eq 'ARRAY') ? (@$fh) : ($fh)) {
      (ref($channel) eq 'CODE')
        ? $channel->($message, $self)
        : print {$channel} $message;
   }
   return;
} ## end sub emit_log

sub log {
   my $self = shift;
   return if $self->{level} == $DEAD;

   my $level = shift;
   return if $level > $self->{level};

   my %data_for = (
      level   => $level,
      message => \@_,
      (exists($self->{loglocal}) ? (loglocal => $self->{loglocal}) : ()),
   );
   my $message = sprintf $self->{format},
     map { $format_for{$_->[0]}[1]->(\%data_for, @$_); } @{$self->{args}};

   return $self->emit_log($message);
} ## end sub log

sub ALWAYS { return $_instance->log($OFF, @_); }

sub _exit {
   my $self = shift || $_instance;
   exit $self->{logexit_code} if defined $self->{logexit_code};
   exit $Log::Log4perl::LOGEXIT_CODE
     if defined $Log::Log4perl::LOGEXIT_CODE;
   exit 1;
} ## end sub _exit

sub logwarn {
   my $self = shift;
   $self->warn(@_);

   # default warning when nothing is passed to warn
   push @_, "Warning: something's wrong" unless @_;

   # add 'at <file> line <line>' unless argument ends in "\n";
   my (undef, $file, $line) = caller(1);
   push @_, sprintf " at %s line %d.\n", $file, $line
     if substr($_[-1], -1, 1) ne "\n";

   # go for it!
   CORE::warn(@_) if $LOGDIE_MESSAGE_ON_STDERR;
} ## end sub logwarn

sub logdie {
   my $self = shift;
   $self->fatal(@_);

   # default die message when nothing is passed to die
   push @_, "Died" unless @_;

   # add 'at <file> line <line>' unless argument ends in "\n";
   my (undef, $file, $line) = caller(1);
   push @_, sprintf " at %s line %d.\n", $file, $line
     if substr($_[-1], -1, 1) ne "\n";

   # go for it!
   CORE::die(@_) if $LOGDIE_MESSAGE_ON_STDERR;

   $self->_exit();
} ## end sub logdie

sub logexit {
   my $self = shift;
   $self->fatal(@_);
   $self->_exit();
}

sub logcarp {
   my $self = shift;
   require Carp;
   $Carp::Internal{$_} = 1 for __PACKAGE__;
   if ($self->is_warn()) {    # avoid unless we're allowed to emit
      my $message = Carp::shortmess(@_);
      $self->warn($_) for split m{\n}mxs, $message;
   }
   if ($LOGDIE_MESSAGE_ON_STDERR) {
      local $Carp::CarpLevel = $Carp::CarpLevel + 1;
      Carp::carp(@_);
   }
   return;
} ## end sub logcarp

sub logcluck {
   my $self = shift;
   require Carp;
   $Carp::Internal{$_} = 1 for __PACKAGE__;
   if ($self->is_warn()) {    # avoid unless we're allowed to emit
      my $message = Carp::longmess(@_);
      $self->warn($_) for split m{\n}mxs, $message;
   }
   if ($LOGDIE_MESSAGE_ON_STDERR) {
      local $Carp::CarpLevel = $Carp::CarpLevel + 1;
      Carp::cluck(@_);
   }
   return;
} ## end sub logcluck

sub logcroak {
   my $self = shift;
   require Carp;
   $Carp::Internal{$_} = 1 for __PACKAGE__;
   if ($self->is_fatal()) {    # avoid unless we're allowed to emit
      my $message = Carp::shortmess(@_);
      $self->fatal($_) for split m{\n}mxs, $message;
   }
   if ($LOGDIE_MESSAGE_ON_STDERR) {
      local $Carp::CarpLevel = $Carp::CarpLevel + 1;
      Carp::croak(@_);
   }
   $self->_exit();
} ## end sub logcroak

sub logconfess {
   my $self = shift;
   require Carp;
   $Carp::Internal{$_} = 1 for __PACKAGE__;
   if ($self->is_fatal()) {    # avoid unless we're allowed to emit
      my $message = Carp::longmess(@_);
      $self->fatal($_) for split m{\n}mxs, $message;
   }
   if ($LOGDIE_MESSAGE_ON_STDERR) {
      local $Carp::CarpLevel = $Carp::CarpLevel + 1;
      Carp::confess(@_);
   }
   $self->_exit();
} ## end sub logconfess

sub level {
   my $self = shift;
   $self = $_instance unless ref $self;
   if (@_) {
      my $level = shift;
      return unless exists $id_for{$level};
      $self->{level} = $id_for{$level};
      $self->{_count}++;
   } ## end if (@_)
   return $self->{level};
} ## end sub level

sub _set_level_if_first {
   my ($self, $level) = @_;
   if (!$self->{_count}) {
      $self->level($level);
      delete $self->{_count};
   }
   return;
} ## end sub _set_level_if_first

BEGIN {

   # Time tracking's start time. Used to be tied to $^T but Log::Log4perl
   # does differently and uses Time::HiRes if available
   my $has_time_hires;
   my $gtod = sub { return (time(), 0) };
   eval {
      require Time::HiRes;
      $has_time_hires = 1;
      $gtod           = \&Time::HiRes::gettimeofday;
   };

   my $start_time = [$gtod->()];

   # For supporting %R
   my $last_log = $start_time;

   # Timezones are... differently supported somewhere
   my $strftime_has_tz_offset =
      POSIX::strftime('%z', localtime()) =~ m<\A [-+] \d{4} \z>mxs;
   if (! $strftime_has_tz_offset) {
      require Time::Local;
   }

   { # alias to the one in Log::Log4perl, for easier switching towards that
      no strict 'refs';
      *caller_depth = *Log::Log4perl::caller_depth;
   }
   our $caller_depth;
   $caller_depth ||= 0;

   # %format_for idea from Log::Tiny by J. M. Adler
   %format_for = (    # specifiers according to Log::Log4perl
      c => [s => sub { 'main' }],
      C => [
         s => sub {
            my ($internal_package) = caller 0;
            my $i = 1;
            my $package;
            while ($i <= 4) {
               ($package) = caller $i;
               return '*undef*' unless defined $package;
               last if $package ne $internal_package;
               ++$i;
            } ## end while ($i <= 4)
            return '*undef' if $i > 4;
            ($package) = caller($i += $caller_depth) if $caller_depth;
            return $package;
         },
      ],
      d => [
         s => sub {
            my ($epoch) = @{shift->{tod} ||= [$gtod->()]};
            return POSIX::strftime('%Y/%m/%d %H:%M:%S', localtime($epoch));
         },
      ],
      D => [
         s => sub {
            my ($data, $op, $options) = @_;
            $options = '{}' unless defined $options;
            $options = substr $options, 1, length($options) - 2;
            my %flag_for = map { $_ => 1 } split /\s*,\s*/, lc($options);
            my ($s, $u) = @{$data->{tod} ||= [$gtod->()]};
            $u = substr "000000$u", -6, 6;    # padding left with 0
            return POSIX::strftime("%Y-%m-%d %H:%M:%S.$u+0000", gmtime $s)
              if $flag_for{utc};

            my @localtime = localtime $s;
            return POSIX::strftime("%Y-%m-%d %H:%M:%S.$u%z", @localtime)
               if $strftime_has_tz_offset;

            my $sign = '+';
            my $offset = Time::Local::timegm(@localtime) - $s;
            ($sign, $offset) = ('-', -$offset) if $offset < 0;
            my $z = sprintf '%s%02d%02d',
              $sign,                    # sign
              int($offset / 3600),      # hours
              (int($offset / 60) % 60); # minutes
            return POSIX::strftime("%Y-%m-%d %H:%M:%S.$u$z", @localtime);
         },
         'optional'
      ],
      e => [
         s => sub {
            my ($data, $op, $options) = @_;
            $data->{tod} ||= [$gtod->()];     # guarantee consistency here
            my $local = $data->{loglocal} or return '';
            my $key = substr $options, 1, length($options) - 2;
            return '' unless exists $local->{$key};
            my $target = $local->{$key};
            return '' unless defined $target;
            my $reft = ref $target or return $target;
            return '' unless $reft eq 'CODE';
            return $target->($data, $op, $options);
         },
         'required',
      ],
      F => [
         s => sub {
            my ($internal_package) = caller 0;
            my $i = 1;
            my ($package, $file);
            while ($i <= 4) {
               ($package, $file) = caller $i;
               return '*undef*' unless defined $package;
               last if $package ne $internal_package;
               ++$i;
            } ## end while ($i <= 4)
            return '*undef' if $i > 4;
            (undef, $file) = caller($i += $caller_depth) if $caller_depth;
            return $file;
         },
      ],
      H => [
         s => sub {
            eval { require Sys::Hostname; Sys::Hostname::hostname() }
              || '';
         },
      ],
      l => [
         s => sub {
            my ($internal_package) = caller 0;
            my $i = 1;
            my ($package, $filename, $line);
            while ($i <= 4) {
               ($package, $filename, $line) = caller $i;
               return '*undef*' unless defined $package;
               last if $package ne $internal_package;
               ++$i;
            } ## end while ($i <= 4)
            return '*undef' if $i > 4;
            (undef, $filename, $line) = caller($i += $caller_depth)
              if $caller_depth;
            my (undef, undef, undef, $subroutine) = caller($i + 1);
            $subroutine = "main::" unless defined $subroutine;
            return sprintf '%s %s (%d)', $subroutine, $filename, $line;
         },
      ],
      L => [
         d => sub {
            my ($internal_package) = caller 0;
            my $i = 1;
            my ($package, $line);
            while ($i <= 4) {
               ($package, undef, $line) = caller $i;
               return -1 unless defined $package;
               last if $package ne $internal_package;
               ++$i;
            } ## end while ($i <= 4)
            return -1 if $i > 4;
            (undef, undef, $line) = caller($i += $caller_depth)
              if $caller_depth;
            return $line;
         },
      ],
      m => [
         s => sub {
            join(
               (defined $, ? $, : ''),
               map { ref($_) eq 'CODE' ? $_->() : $_; } @{shift->{message}}
            );
         },
      ],
      M => [
         s => sub {
            my ($internal_package) = caller 0;
            my $i = 1;
            while ($i <= 4) {
               my ($package) = caller $i;
               return '*undef*' unless defined $package;
               last if $package ne $internal_package;
               ++$i;
            } ## end while ($i <= 4)
            return '*undef' if $i > 4;
            $i += $caller_depth if $caller_depth;
            my (undef, undef, undef, $subroutine) = caller($i + 1);
            $subroutine = "main::" unless defined $subroutine;
            return $subroutine;
         },
      ],
      n => [s => sub { "\n" },],
      p => [s => sub { $name_of{shift->{level}} },],
      P => [d => sub { $$ },],
      r => [
         d => sub {
            my ($s, $u) = @{shift->{tod} ||= [$gtod->()]};
            $s -= $start_time->[0];
            my $m = int(($u - $start_time->[1]) / 1000);
            ($s, $m) = ($s - 1, $m + 1000) if $m < 0;
            return $m + 1000 * $s;
         },
      ],
      R => [
         d => sub {
            my ($sx, $ux) = @{shift->{tod} ||= [$gtod->()]};
            my $s = $sx - $last_log->[0];
            my $m = int(($ux - $last_log->[1]) / 1000);
            ($s, $m) = ($s - 1, $m + 1000) if $m < 0;
            $last_log = [$sx, $ux];
            return $m + 1000 * $s;
         },
      ],
      T => [
         s => sub {
            my ($internal_package) = caller 0;
            my $level = 1;
            while ($level <= 4) {
               my ($package) = caller $level;
               return '*undef*' unless defined $package;
               last if $package ne $internal_package;
               ++$level;
            } ## end while ($level <= 4)
            return '*undef' if $level > 4;

            # usage of Carp::longmess() and substitutions is mostly copied
            # from Log::Log4perl for better alignment and easier
            # transition to the "bigger" module
            local $Carp::CarpLevel =
              $Carp::CarpLevel + $level + $caller_depth;
            chomp(my $longmess = Carp::longmess());
            $longmess =~ s{(?:\A\s*at.*?\n|^\s*)}{}mxsg;
            $longmess =~ s{\n}{, }g;
            return $longmess;
         },
      ],
   );

   # From now on we're going to play with GLOBs...
   no strict 'refs';

   for my $name (qw( FATAL ERROR WARN INFO DEBUG TRACE )) {

      # create the ->level methods
      *{__PACKAGE__ . '::' . lc($name)} = sub {
         my $self = shift;
         return $self->log($$name, @_);
      };

      # create ->is_level and ->isLevelEnabled methods as well
      *{__PACKAGE__ . '::is' . ucfirst(lc($name)) . 'Enabled'} =
        *{__PACKAGE__ . '::is_' . lc($name)} = sub {
         return 0 if $_[0]->{level} == $DEAD || $$name > $_[0]->{level};
         return 1;
        };
   } ## end for my $name (qw( FATAL ERROR WARN INFO DEBUG TRACE ))

   for my $name (
      qw(
      FATAL ERROR WARN INFO DEBUG TRACE
      LOGWARN LOGDIE LOGEXIT
      LOGCARP LOGCLUCK LOGCROAK LOGCONFESS
      )
     )
   {
      *{__PACKAGE__ . '::' . $name} = sub {
         $_instance->can(lc $name)->($_instance, @_);
      };
   } ## end for my $name (qw( FATAL ERROR WARN INFO DEBUG TRACE...))

   for my $accessor (qw( fh logexit_code )) {
      *{__PACKAGE__ . '::' . $accessor} = sub {
         my $self = shift;
         $self = $_instance unless ref $self;
         $self->{$accessor} = shift if @_;
         return $self->{$accessor};
      };
   } ## end for my $accessor (qw( fh logexit_code ))

   my $index = -1;
   for my $name (qw( DEAD OFF FATAL ERROR WARN INFO DEBUG TRACE )) {
      $name_of{$$name = $index} = $name;
      $id_for{$name}  = $index;
      $id_for{$index} = $index;
      ++$index;
   } ## end for my $name (qw( DEAD OFF FATAL ERROR WARN INFO DEBUG TRACE ))

   get_logger();    # initialises $_instance;
} ## end BEGIN

1;                  # Magic true value required at end of module

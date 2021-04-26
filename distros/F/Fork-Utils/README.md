# perl_fork_utils

### NAME

    Fork::Utils - set of usefull methods to work with processes and signals

### SYNOPSIS
```perl
        use Fork::Utils qw/ safe_exec /;

        my $result = safe_exec(
          'code'   => sub { my_super_sub( @_ ); },
          'args'   => [ @params ],
          'sigset' => [ qw/ CHLD TERM INT QUIT ALRM / ]
        );
```

### DESCRIPTION

    This package provides some methods that can be helpfull while working
    with sub-processes and signals.

##### safe_exec
    Gets a hash with arguments, one of them is code reference is required to
    be executed in safe context. "Safe context" means context which can't be
    accidently interrupted by some signals.

    This method receives list of signals required to be blocked while code
    execution. Once code is executed the original signal mask will be
    restored.

    Any signal (except KILL, STOP) can be blocked.

    The signal names can be taken from $Config{'sig_names'}.

    Returns a result of mentioned code reference as "$code->( @$args )".
    Be aware that in current implementation this methods can't return the list.
    The return value looks like the one shown below:

```perl
        my $result = $code->( @$args );
```

    In case of any error in the executed code reference tha standard $@
    variable will be set.

###### code

          it's a code reference to be executed in safe context

###### args

          it's an array reference of arguments required to be passed into C<code> (see above)

###### sigset

          it's an array reference of signal names to be blocked while executing the C<code> (see above)

###### replace_mask

          It's a flag, by default it's turned off.
  
          If it's off than passed signals will be added to the current signal mask,
          otherwise mask will be replaced with new one built with mentioned signals

### AUTHOR
    Chernenko Dmitiry cdn@cpan.org

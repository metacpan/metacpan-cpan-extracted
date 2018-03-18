use strict;
use warnings;

package Footprintless::Command;
$Footprintless::Command::VERSION = '1.28';
# ABSTRACT: A factory for building common commands
# PODNAME: Footprintless::Command

use Exporter qw(import);
our @EXPORT_OK = qw(
    batch_command
    command
    command_options
    cp_command
    mkdir_command
    pipe_command
    rm_command
    sed_command
    tail_command
    write_command
);

use File::Spec;

sub batch_command {
    my ( @commands, $batch_options, $command_options );
    (@commands) = @_;
    $command_options = pop(@commands)
        if ( ref( $commands[$#commands] ) eq 'Footprintless::Command::CommandOptions' );
    $batch_options = pop(@commands) if ( ref( $commands[$#commands] ) eq 'HASH' );

    push( @commands, $command_options ) if ($command_options);

    wrap(
        $batch_options || {},
        @commands,
        sub {
            return @_;
        }
    );
}

sub command {
    wrap(
        {},
        @_,
        sub {
            return shift;
        }
    );
}

sub command_options {
    return Footprintless::Command::CommandOptions->new(@_);
}

sub cp_command {
    my ( $source_path, $source_command_options, $destination_path, $destination_command_options,
        %cp_options );
    $source_path            = _escape_path(shift);
    $source_command_options = shift
        if ( ref( $_[0] ) eq 'Footprintless::Command::CommandOptions' );
    $destination_path            = _escape_path(shift);
    $destination_command_options = shift
        if ( ref( $_[0] ) eq 'Footprintless::Command::CommandOptions' );
    %cp_options = @_;

    $source_command_options      = command_options() unless ($source_command_options);
    $destination_command_options = command_options() unless ($destination_command_options);

    my $source_command;
    my $destination_command;
    if ( $cp_options{file} ) {

        # is a file, so use cat | dd
        if ( $cp_options{compress} ) {
            $source_command = command( "gzip -c $source_path", $source_command_options );
            $destination_command =
                pipe_command( "gunzip", "dd of=$destination_path", $destination_command_options );
        }
        else {
            $source_command = command( "cat $source_path", $source_command_options );
            $destination_command =
                command( "dd of=$destination_path", $destination_command_options );
        }
    }
    else {
        # is a directory, so use tar or unzip
        if ( $cp_options{archive} && $cp_options{archive} eq 'zip' ) {
            my $temp_zip = File::Spec->catfile( $destination_path,
                $cp_options{unzip_temp_file} || "temp_cp_command.zip" );
            $source_command =
                command(
                batch_command( "cd $source_path", "zip -qr - .", { subshell => "bash -c " } ),
                $source_command_options );
            $destination_command = batch_command(
                "dd of=$temp_zip",     "unzip -qod $destination_path $temp_zip",
                rm_command($temp_zip), $destination_command_options
            );
        }
        else {
            # default, use tar
            my @parts             = ("tar -c -C $source_path .");
            my @destination_parts = ();
            if ( $cp_options{status} ) {
                push(
                    @parts,
                    join(
                        '',
                        'pv -f -s `',
                        _sudo_command(
                            $source_command_options
                            ? ( $source_command_options->get_sudo_command(),
                                $source_command_options->get_sudo_username()
                                )
                            : ( undef, undef ),
                            pipe_command( "du -sb $source_path", 'cut -f1' )
                        ),
                        '`'
                    )
                );
            }
            if ( $cp_options{compress} ) {
                push( @parts,             'gzip' );
                push( @destination_parts, 'gunzip' );
            }
            push(
                @destination_parts,
                _sudo_command(
                    $destination_command_options
                    ? ( $destination_command_options->get_sudo_command(),
                        $destination_command_options->get_sudo_username()
                        )
                    : ( undef, undef ),
                    "tar --no-overwrite-dir -x -C $destination_path"
                )
            );

            $source_command = command( pipe_command(@parts), $source_command_options );
            $destination_command = command( pipe_command(@destination_parts),
                $destination_command_options->clone( sudo_username => undef ) );
        }
    }

    return pipe_command( $source_command, $destination_command );
}

sub _escape_path {
    my ($path) = @_;
    $path =~ s/(['"`\s])/\\$1/g;
    return $path;
}

sub mkdir_command {
    wrap(
        {},
        @_,
        sub {
            return 'mkdir -p "' . join( '" "', @_ ) . '"';
        }
    );
}

sub pipe_command {
    wrap(
        { command_separator => '|' },
        @_,
        sub {
            return @_;
        }
    );
}

sub _quote_command {
    my ($command) = @_;
    $command =~ s/\\/\\\\/g;
    $command =~ s/\$/\\\$/g;
    $command =~ s/`/\\`/g;    # for `command`
    $command =~ s/"/\\"/g;
    return "\"$command\"";
}

sub rm_command {
    Footprintless::Command::wrap(
        {},
        @_,
        sub {
            my ( @dirs, @files );
            foreach my $entry (@_) {
                if ( $entry =~ /(?:\/|\\)$/ ) {
                    push( @dirs, $entry );
                }
                else {
                    push( @files, $entry );
                }
            }

            if (@dirs) {
                if (@files) {
                    return batch_command(
                        'rm -rf "' . join( '" "', sort(@dirs) ) . '"',
                        'rm -f "' . join( '" "', sort(@files) ) . '"',
                        { subshell => 'bash -c ' }
                    );
                }
                else {
                    return 'rm -rf "' . join( '" "', sort(@dirs) ) . '"';
                }
            }
            else {
                return 'rm -f "' . join( '" "', sort(@files) ) . '"';
            }
        }
    );
}

sub sed_command {
    wrap(
        {},
        @_,
        sub {
            my @args    = @_;
            my $options = {};

            if ( ref( $args[$#args] ) eq 'HASH' ) {
                $options = pop(@args);
            }

            my $command = 'sed';
            $command .= ' -i' if ( $options->{in_place} );
            if ( defined( $options->{temp_script_file} ) ) {
                my $temp_script_file_name = $options->{temp_script_file}->filename();
                print( { $options->{temp_script_file} } join( ' ', '', map {"$_;"} @args ) )
                    if ( scalar(@args) );
                print(
                    { $options->{temp_script_file} } join( ' ',
                        '',
                        map {"s/$_/$options->{replace_map}{$_}/g;"}
                            keys( %{ $options->{replace_map} } ) )
                ) if ( defined( $options->{replace_map} ) );
                $options->{temp_script_file}->flush();
                $command .= " -f $temp_script_file_name";
            }
            else {
                $command .= join( ' ', '', map {"-e '$_'"} @args ) if ( scalar(@args) );
                $command .= join( ' ',
                    '',
                    map {"-e 's/$_/$options->{replace_map}{$_}/g'"}
                        keys( %{ $options->{replace_map} } ) )
                    if ( defined( $options->{replace_map} ) );
            }
            $command .= join( ' ', '', @{ $options->{files} } ) if ( $options->{files} );

            return $command;
        }
    );
}

sub _sudo_command {
    my ( $sudo_command, $sudo_username, $command ) = @_;
    if ( defined($sudo_username) ) {
        $command =
              ( $sudo_command  ? "$sudo_command "     : 'sudo ' )
            . ( $sudo_username ? "-u $sudo_username " : '' )
            . $command;
    }
    return $command;
}

sub tail_command {
    Footprintless::Command::wrap(
        {},
        @_,
        sub {
            my ( $file, %options ) = @_;
            my @command = ('tail');
            if ( $options{follow} ) {
                push( @command, '-f' );
            }
            elsif ( $options{lines} ) {
                push( @command, '-n', $options{lines} );
            }
            push( @command, $file );
            return join( ' ', @command );
        }
    );
}

sub write_command {
    my ( $filename, @lines, $write_options, $command_options );
    $filename        = shift;
    @lines           = @_;
    $command_options = pop(@lines)
        if ( ref( $lines[$#lines] ) eq 'Footprintless::Command::CommandOptions' );
    $write_options = pop(@lines) if ( ref( $lines[$#lines] ) eq 'HASH' );

    my $remote_command = "dd of=$filename";
    if ( defined($write_options) && defined( $write_options->{mode} ) ) {
        if ( defined($command_options) ) {
            $remote_command =
                batch_command( $remote_command, "chmod $write_options->{mode} $filename",
                $command_options );
        }
        elsif ( defined($command_options) ) {
            $remote_command =
                batch_command( $remote_command, "chmod $write_options->{mode} $filename" );
        }
    }
    elsif ( defined($command_options) ) {
        $remote_command = command( $remote_command, $command_options );
    }

    my $line_separator =
        ( defined($write_options) && defined( $write_options->{line_separator} ) )
        ? $write_options->{line_separator}
        : '\n';
    return pipe_command( 'printf "' . join( $line_separator, @lines ) . '"', $remote_command );
}

# Handles wrapping commands with possible ssh and command prefix
sub wrap {
    my $wrap_options = shift;
    my $builder      = pop;
    my @args         = @_;
    my ( $ssh, $username, $hostname, $sudo_command, $sudo_username, $pretty );

    if ( ref( $args[$#args] ) eq 'Footprintless::Command::CommandOptions' ) {
        my $options = pop(@args);
        $ssh           = $options->get_ssh() || 'ssh';
        $username      = $options->get_username();
        $hostname      = $options->get_hostname();
        $sudo_command  = $options->get_sudo_command();
        $sudo_username = $options->get_sudo_username();
        $pretty        = $options->get_pretty();
    }

    my $destination_command = '';
    my $command_separator   = $wrap_options->{command_separator} || ';';
    my $commands            = 0;
    foreach my $command ( &$builder(@args) ) {
        if ( defined($command) ) {
            if ( $commands++ > 0 ) {
                $destination_command .= $command_separator;
                if ($pretty) {
                    $destination_command .= "\n";
                }
            }

            $command =~ s/^(.*?[^\\]);$/$1/;    # from find -exec

            $command = _sudo_command( $sudo_command, $sudo_username, $command );

            $destination_command .= $command;
        }
    }

    if ( $wrap_options->{subshell} ) {
        $destination_command = $wrap_options->{subshell} . _quote_command($destination_command);
    }

    if ( !defined($username) && !defined($hostname) ) {

        # silly to ssh to localhost as current user, so dont
        return $destination_command;
    }

    my $userAt =
        $username
        ? ( ( $ssh =~ /plink(?:\.exe)?$/ ) ? "-l $username " : "$username\@" )
        : '';

    $destination_command = _quote_command($destination_command);
    return "$ssh $userAt" . ( $hostname || 'localhost' ) . " $destination_command";
}

package Footprintless::Command::CommandOptions;
$Footprintless::Command::CommandOptions::VERSION = '1.28';
sub new {
    return bless( {}, shift )->_init(@_);
}

sub clone {
    my ( $instance, %options ) = @_;

    if ( exists( $instance->{hostname} ) && !exists( $options{hostname} ) ) {
        $options{hostname} = $instance->{hostname};
    }
    if ( exists( $instance->{ssh} ) && !exists( $options{ssh} ) ) {
        $options{ssh} = $instance->{ssh};
    }
    if ( exists( $instance->{username} ) && !exists( $options{username} ) ) {
        $options{username} = $instance->{username};
    }
    if ( exists( $instance->{sudo_command} ) && !exists( $options{sudo_command} ) ) {
        $options{sudo_command} = $instance->{sudo_command};
    }
    if ( exists( $instance->{sudo_username} ) && !exists( $options{sudo_username} ) ) {
        $options{sudo_username} = $instance->{sudo_username};
    }
    if ( exists( $instance->{pretty} ) && !exists( $options{pretty} ) ) {
        $options{pretty} = $instance->{pretty};
    }

    return new( ref($instance), %options );
}

sub get_hostname {
    return $_[0]->{hostname};
}

sub get_pretty {
    return $_[0]->{pretty};
}

sub get_ssh {
    return $_[0]->{ssh};
}

sub get_sudo_command {
    return $_[0]->{sudo_command};
}

sub get_sudo_username {
    return $_[0]->{sudo_username};
}

sub get_username {
    return $_[0]->{username};
}

sub _init {
    my ( $self, %options ) = @_;

    $self->{hostname}      = $options{hostname}      if ( defined( $options{hostname} ) );
    $self->{ssh}           = $options{ssh}           if ( defined( $options{ssh} ) );
    $self->{username}      = $options{username}      if ( defined( $options{username} ) );
    $self->{sudo_command}  = $options{sudo_command}  if ( defined( $options{sudo_command} ) );
    $self->{sudo_username} = $options{sudo_username} if ( defined( $options{sudo_username} ) );
    $self->{pretty}        = $options{pretty}        if ( defined( $options{pretty} ) );

    return $self;
}

__END__

=pod

=head1 NAME

Footprintless::Command - A factory for building common commands

=head1 VERSION

version 1.28

=head1 SYNOPSIS

  use Footprintless::Command qw(command batch_command mkdir_command pipe_command rm_command sed_command);
  my $command = command( 'echo' ); # echo

  # ssh foo "echo"
  $command = command( 'echo', command_options( hostname=>'foo' ) ); 

  # ssh bar@foo "echo"
  $command = command( 'echo', command_options( username=>'bar',hostname=>'foo' ) ); 
  
  # plink -l bar foo "echo"
  $command = command( 'echo', command_options( username=>'bar',hostname=>'foo',ssh=>'plink' ) ); 
  
  # cd foo;cd bar
  $command = batch_command( 'cd foo', 'cd bar' ); 
  
  # ssh baz "cd foo;cd bar"
  $command = batch_command( 'cd foo', 'cd bar', command_options( hostname=>'baz' ) ); 
  
  # ssh baz "bash -c \"sudo cd foo;sudo cd bar\""
  $command = batch_command( 'cd foo', 'cd bar', {subshell => 'bash -c' }, command_options( hostname=>'baz',sudo_username=>'' ) ); 
  
  # ssh baz "mkdir -p \"foo\" \"bar\""
  $command = mkdir_command( 'foo', 'bar', command_options( hostname=>'baz' ) ); 

  # cat abc|ssh baz "dd of=def"
  $command = pipe_command( 
          'cat abc', 
          command( 'dd of=def', command_options( hostname=>'baz' ) ) 
      ); 

  # ssh fred@baz "sudo -u joe rm -rf \"foo\" \"bar\""
  $command = rm_command( 'foo', 'bar', command_options( username=>'fred',hostname=>'baz',sudo_username=>'joe' ) ); 
  
  # sed -e 's/foo/bar/'
  $command = sed_command( 's/foo/bar/' ); 
  
  
  # curl http://www.google.com|sed -e \'s/google/gaggle/g\'|ssh fred@baz "sudo -u joe dd of=\"/tmp/gaggle.com\"";ssh fred@baz "sudo -u joe rm -rf \"/tmp/google.com\"";
  my $command_options = command_options( username=>'fred',hostname=>'baz',sudo_username=>'joe' );
  $command = batch_command(
          pipe_command( 
              'curl http://www.google.com',
              sed_command( {replace_map=>{google=>'gaggle'}} ),
              command( 'dd of="/tmp/gaggle.com"', $command_options )
          ),
          rm_command( '/tmp/google.com', $command_options )
      );

=head1 DESCRIPTION

The subroutines exported by this module can build shell command strings that
can be executed by IPC::Open3::Callback, Footprintless::CommandRunner,
``, system(), or even plain old open 1, 2, or 3.  There is not much
point to I<shelling> out for commands locally as there is almost certainly a
perl function/library capable of doing whatever you need in perl code. However,
If you are designing a footprintless agent that will run commands on remote
machines using existing tools (gnu/powershell/bash...) these utilities can be
very helpful.  All functions in this module can take a C<command_options>
hash defining who/where/how to run the command.

=head1 OPTIONS

=head1 FUNCTIONS

=head2 batch_command($command1, $command2, ..., $commandN, [\%batch_options], [$command_options])

This will join all the commands with a C<;> and apply the supplied 
C<command_options> to the result.  The supported C<batch_options> are:

=over 4

=item subshell

The subshell to run the commands under, must end with C<-c>. (ex: C<'bash -c'>)

=back

=head2 command($command, [$command_options])

This wraps the supplied command with all the destination options.  If no 
options are supplied, $command is returned.

=head2 command_options(%options) 

Returns a C<command_options> object to be supplied to other commands.
All commands can be supplied with C<command_options>.  
C<command_options> control who/where/how to run the command.  The supported
options are:

=over 4

=item ssh

The ssh command to use, defaults to C<ssh>.  You can use this to specify other
commands like C<plink> for windows or an implementation of C<ssh> that is not
in your path.

=item sudo_command

The actual C<sudo> command.  Most likely you will want to leave this undefined
and let C<sudo> be found in your C<$PATH>.  However, if for some reason you 
need to use a different version (ex: C</usr/depot/bin/sudo>, then this provides 
that option.

=item sudo_username

Prefixes your command thusly: C<sudo -u $sudo_username $command>.  If combined
with a remote hostname, the C<sudo> will be executed on the remote system.  For
example: C<ssh $hostname "sudo -u $sudo_user \"$command\"">.

=item username

The username to C<ssh> with. If using C<ssh>, this will result in, 
C<ssh $username@$hostname> but if using C<plink> it will result in 
C<plink -l $username $hostname>.

=item hostname

The hostname/IP of the server to run this command on. If localhost, and no 
username is specified, the command will not be wrapped in C<ssh>

=back

=head2 cp_command($source_path, [$source_command_options], $destination_path, [$destination_command_options], %cp_options)

This generates a command for copying files or directories from a source to
a destination.  Both source and destination have optional C<command_options>, 
and the C<cp_command> itself has the following options:

=over 4

=item archive

If specified and set to 'zip', then zip will be used to archive the source
before sending it to the destination.  Otherwise, tar will be used.  Note,
that if C<file =E<gt> 1> then this is ignored.

=item compress

If supplied and true, then the source data will be compressed before sending
to the destination where it will be uncompressed before writing out.  Note,
that if you use C<archive =E<gt> 'zip'> then this is ignored as zip implies 
compression.

=item file

If supplied and true, then this is a file copy, otherwise it is a directory 
copy.

=item status

If supplied, a status indicator will be printed to STDERR.  This option uses
the unix C<pv> command which is typically not installed by default.  Also, this
option only works with C<archive> set to tar (the default), and C<file> set to
false (the default).

=back

=head2 mkdir_command($path1, $path2, ..., $pathN, [$command_options])

Results in C<mkdir -p $path1 $path2 ... $pathN> with the 
C<command_options> applied.

=head2 pipe_command($command1, $command2, ..., $commandN, [$command_options])

Identical to 
L<batch_command|"batch_command( $command1, $command2, ..., $commandN, [$command_options] )">
except uses C<\|> to separate the commands instead of C<;>.

=head2 rm_command($path1, $path2, ..., $pathN, [$command_options])

Results in C<rm -rf $path1 $path2 ... $pathN> with the 
C<command_options> applied. This is a I<VERY> dangerous command and should
be used with care.

=head2 sed_command($expression1, $expression2, ..., $expressionN, [$command_options])

Constructs a sed command

=over 4

=item files

An arrayref of files to apply the sed expressions to.  For use when not piping
from another command.

=item in_place

If specified, the C<-i> option will be supplied to C<sed> thus modifying the
file argument in place. Not useful for piping commands together, but can be 
useful if you copy a file to a temp directory, modify it in place, then 
transfer the file and delete the temp directory.  It would be more secure to 
follow this approach when using sed to fill in passwords in config files. For
example, if you wanted to use sed substitions to set passwords in a config file
template and then transfer that config file to a remote server:

C</my/config/passwords.cfg>

  app1.username=foo
  app1.password=##APP1_PASSWORD##
  app2.username=bar
  app2.password=##APP2_PASSWORD##

C<deploy_passwords.pl>

  use Footprintless::Command qw(batch_command command pipe_command sed_command);
  use Footprintless::CommandRunner;
  use File::Temp;
  
  my $temp_dir = File::Temp->newdir();
  my $temp_script_file = File::Temp->new();
  Footprintless::CommandRunner->new()->run_or_die(
      batch_command( 
          "cp /my/config/passwords.cfg $temp_dir->filename()/passwords.cfg",
          sed_command( 
              "s/##APP1_PASSWORD##/set4app1/g",
              "s/##APP2_PASSWORD##/set4app2/g", 
              {
                  in_place=>1,
                  temp_script_file=>$temp_script_file,
                  files=>[$temp_dir->filename()/passwords.cfg] 
              } 
          ),
          pipe_command( 
              "cat $temp_dir->filename()/passwords.cfg",
              command( "dd of='/remote/config/passwords.cfg'", {hostname=>'remote_host'} ) );
      )
  );

=item replace_map

A map used to construct a sed expression where the key is the match portion 
and the value is the replace portion. For example: C<{'key'=E<gt>'value'}> would 
result in C<'s/key/value/g'>.

=item temp_script_file

Specifies a file to write the sed script to rather than using the console.  
This is useful for avoiding generating commands that would get executed in the 
console that have protected information like passwords. If passwords are 
issued on the console, they might show up in the command history...

=back

=head2 tail_command($filename, [\%tail_options], [$command_options])

Will read lines from the end of C<$filename>.  The supported tail options are:

=over 4

=item follow

If I<truthy>, new lines will be read as the file gets written to.

=item lines

The number of lines to obtain from the end fo the file.

=back

=head2 write_command($filename, @lines, [\%write_options], [$command_options])

Will write C<@lines> to C<$filename>.  The supported write options are:

=over 4

=item mode

The file mode to set for C<$filename>.

=item line_separator

The the separator to use between lines (default: C<\n>).

=back

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless|Footprintless>

=item *

L<Footprintless::CommandRunner|Footprintless::CommandRunner>

=back

=for Pod::Coverage wrap

=cut

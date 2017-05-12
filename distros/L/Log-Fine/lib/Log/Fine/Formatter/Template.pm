
=head1 NAME

Log::Fine::Formatter::Template - Format log messages using template

=head1 SYNOPSIS

Formats log messages for output using a user-defined template spec.

    use Log::Fine::Formatter::Template;
    use Log::Fine::Handle::Console;

    # Instantiate a handle
    my $handle = Log::Fine::Handle::Console->new();

    # Instantiate a formatter
    my $formatter = Log::Fine::Formatter::Template
        ->new(
          name             => 'template0',
          template         => "[%%TIME%%] %%LEVEL%% (%%FILENAME%%:%%LINENO%%) %%MSG%%\n",
          timestamp_format => "%y-%m-%d %h:%m:%s"
    );

    # Set the formatter
    $handle->formatter( formatter => $formatter );

    # When displaying user or group information, use the effective
    # user ID
    my $formatter = Log::Fine::Formatter::Template
        ->new(
          name             => 'template0',
          template         => "[%%TIME%%] %%USER%%@%%HOSTNAME%% %%%LEVEL%% %%MSG%%\n",
          timestamp_format => "%y-%m-%d %h:%m:%s",
          use_effective_id => 1,
    );

    # Format a msg
    my $str = $formatter->format(INFO, "Resistence is futile", 1);

    # Create a template with a custom placeholder
    my $counter = 0;

    # Function that's invoked by the template engine
    sub foobar { ++$counter; }

    my $formatter = Log::Fine::Formatter::Template
        ->new(
          name             => 'template0',
          template         => "[%%TIME%%] %%LEVEL%% (%%FILENAME%%:%%LINENO%%) (COUNT:%%FOOBAR%%) %%MSG%%\n",
          timestamp_format => "%y-%m-%d %h:%m:%s",
          custom_placeholders => {
              FOOBAR => \&foobar,
          });

=head1 DESCRIPTION

The template formatter allows the user to specify the log format via a
template, using placeholders as substitutions.  This provides the user
an alternative way of formatting their log messages without the
necessity of having to write their own formatter object.

Note that if you desire speed, consider rolling your own
Log::Fine::Formatter module.

=cut

use strict;
use warnings;

package Log::Fine::Formatter::Template;

use base qw( Log::Fine::Formatter );

use Log::Fine;
use Log::Fine::Formatter;
use Log::Fine::Levels;

our $VERSION = $Log::Fine::Formatter::VERSION;

use File::Basename;
use Sys::Hostname;

=head1 SUPPORTED PLACEHOLDERS

Placeholders are case-insensitive.  C<%%msg%%> will work just as well
as C<%%MSG%%>

    +---------------+-----------------------------------+
    | %%TIME%%      | Timestamp                         |
    +---------------+-----------------------------------+
    | %%LEVEL%%     | Log Level                         |
    +---------------+-----------------------------------+
    | %%MSG%%       | Log Message                       |
    +---------------+-----------------------------------+
    | %%PACKAGE%%   | Caller package                    |
    +---------------+-----------------------------------+
    | %%FILENAME%%  | Caller filename                   |
    +---------------+-----------------------------------+
    | %%LINENO%%    | Caller line number                |
    +---------------+-----------------------------------+
    | %%SUBROUT%%   | Caller Subroutine                 |
    +---------------+-----------------------------------+
    | %%HOSTLONG%%  | Long Hostname including domain    |
    +---------------+-----------------------------------+
    | %%HOSTSHORT%% | Short Hostname                    |
    +---------------+-----------------------------------+
    | %%LOGIN%%     | User Login                        |
    +---------------+-----------------------------------+
    | %%GROUP%%     | User Group                        |
    +---------------+-----------------------------------+

=head1 CUSTOM PLACEHOLDERS

Custom placeholders may be defined as follows:

  my $counter = 0;

  sub foobar { return ++$counter; } # foobar()

  # Define a template formatter with a custom keyword, FOOBAR
  my $template = Log::Fine::Formatter::Template
      ->new(name      => 'template2',
            template  => "[%%TIME%%] %%LEVEL%% (count:%%FOOBAR%%) %%MSG%%\n",
            custom_placeholders => {
                FOOBAR => \&foobar,
            });

Note that C<< $template->{custom_placeholders} >> is a hash ref with each
key representing a new placeholder that points to a function ref.
Like regular placeholders, custom placeholders are case-insensitive.

=head1 METHODS

=head2 format

Formats the given message for the given level

=head3 Parameters

=over

=item  * level

Level at which to log (see L<Log::Fine::Levels>)

=item  * message

Message to log

=item  * skip

Controls caller skip level

=back

=head3 Returns

The formatted log message as specified by {template}

=cut

sub format
{

        my $self = shift;
        my $lvl  = shift;
        my $msg  = shift;
        my $skip = (defined $_[0]) ? shift : Log::Fine::Logger->LOG_SKIP_DEFAULT;

        my $tmpl    = $self->{template};
        my $v2l     = $self->levelMap()->valueToLevel($lvl);
        my $holders = $self->{_placeHolders} || $self->_placeHolders($tmpl);

        # Increment skip as calls to caller() are now encapsulated in
        # anonymous functions
        $skip++;

        # Level & message are variable values
        $tmpl =~ s/%%LEVEL%%/$v2l/ig;
        $tmpl =~ s/%%MSG%%/$msg/ig;

        # Fill in placeholders
        foreach my $holder (keys %$holders) {
                my $value = &{ $holders->{$holder} }($skip);
                $tmpl =~ s/%%${holder}%%/$value/ig;
        }

        return $tmpl;

}          # format()

# --------------------------------------------------------------------

##
# Initializer for this object

sub _init
{

        my $self = shift;

        # Perform any necessary upper class initializations
        $self->SUPER::_init();

        # Make sure that template is defined
        $self->_fatal("No template specified")
            unless (defined $self->{template}
                    and $self->{template} =~ /\w/);

        # Set use_effective_id to default
        $self->{use_effective_id} = 1
            unless (defined $self->{use_effective_id}
                    and $self->{use_effective_id} =~ /\d/);

        # Do we have custom templates?
        $self->_placeholderValidate()
            if defined $self->{custom_placeholders};

        # Set up some defaults
        $self->_fileName();
        $self->_groupName();
        $self->_hostName();
        $self->_userName();

        return $self;

}          # _init()

##
# Getter/Setter for fileName

sub _fileName
{

        my $self = shift;

        # Should {_fileName} be already cached, then return it, otherwise
        # get the file name, cache it, and return
        $self->{_fileName} = basename $0
            unless (defined $self->{_fileName} and $self->{_fileName} =~ /\w/);

        return $self->{_fileName};

}          # _fileName()

##
# Getter/Setter for group

sub _groupName
{

        my $self = shift;

        # Should {_groupName} be already cached, then return it,
        # otherwise get the group name, cache it, and return
        if (defined $self->{_groupName} and $self->{_groupName} =~ /\w/) {
                return $self->{_groupName};
        } elsif ($self->{use_effective_id}) {
                if ($^O =~ /MSWin32/) {
                        $self->{_groupname} =
                              (defined $ENV{EGID})
                            ? (split(" ", $ENV{EGID}))[0]
                            : 0;
                } else {
                        $self->{_groupName} = getgrgid((split(" ", $)))[0])
                            || "nogroup";
                }
        } else {
                if ($^O =~ /MSWin32/) {
                        $self->{_groupName} =
                              (defined $ENV{GID})
                            ? (split(" ", $ENV{GID}))[0]
                            : 0;
                } else {
                        $self->{_groupname} = getgrgid((split(" ", $())[0])
                            || "nogroup";
                }
        }

        return $self->{_groupName};

}          # _groupName()

##
# Getter/Setter for hostname

sub _hostName
{

        my $self = shift;

        # Should {_fullHost} be already cached, then return it,
        # otherwise get hostname, cache it, and return
        $self->{_fullHost} = hostname() || "{undef}"
            unless (defined $self->{_fullHost} and $self->{_fullHost} =~ /\w/);

        return $self->{_fullHost};

}          # _hostName()

##
# Getter/Setter for placeholders

sub _placeHolders
{

        my $self = shift;
        my $tmpl = shift;

        # Should {_placeHolders} be already cached, then return it,
        # otherwise generate placeholders and return
        if (defined $self->{_placeHolders}
             and ref $self->{_placeHolders} eq "HASH") {
                return $self->{_placeHolders};
        } else {

                my $placeholders = {};

                $placeholders->{time} = sub { return $self->_formatTime() }
                    if ($tmpl =~ /%%TIME%%/i);

                $placeholders->{package} = sub {
                        my $skip = shift;
                        return (caller($skip))[0] || "{undef}";
                    }
                    if ($tmpl =~ /%%PACKAGE%%/i);

                $placeholders->{filename} = sub { return $self->{_fileName} }
                    if ($tmpl =~ /%%FILENAME%%/i);

                $placeholders->{lineno} = sub { my $skip = shift; return (caller($skip))[2] || 0 }
                    if ($tmpl =~ /%%LINENO%%/i);

                $placeholders->{subrout} = sub {
                        my $skip = shift;
                        return (caller(++$skip))[3] || "main";
                    }
                    if ($tmpl =~ /%%SUBROUT%%/i);

                $placeholders->{hostshort} = sub { return (split /\./, $self->{_fullHost})[0] }
                    if ($tmpl =~ /%%HOSTSHORT%%/i);

                $placeholders->{hostlong} = sub { return $self->{_fullHost} }
                    if ($tmpl =~ /%%HOSTLONG%%/i);

                $placeholders->{user} = sub { return $self->{_userName} }
                    if ($tmpl =~ /%%USER%%/i);

                $placeholders->{group} = sub { return $self->{_groupName} }
                    if ($tmpl =~ /%%GROUP%%/i);

                # Check for custom templates
                if (defined $self->{custom_placeholders}) {

                        foreach my $placeholder (keys %{ $self->{custom_placeholders} }) {
                                $placeholders->{$placeholder} = $self->{custom_placeholders}->{$placeholder}
                                    if ($tmpl =~ /%%${placeholder}%%/i);
                        }

                }

                $self->{_placeHolders} = $placeholders;

                return $placeholders;

        }

}          # _placeHolder()

##
# Validator for custom placeholders

sub _placeholderValidate
{

        my $self    = shift;
        my $holders = {};

        $self->_fatal("{custom_placeholders} must be a valid hash ref")
            unless ref $self->{custom_placeholders} eq "HASH";

        foreach my $placeholder (keys %{ $self->{custom_placeholders} }) {

                $self->_fatal(
                              sprintf("custom template '%s' must point to " . "a valid function ref : %s",
                                      $placeholder, ref $self->{custom_placeholders}->{$placeholder})
                ) unless ref $self->{custom_placeholders}->{$placeholder} eq "CODE";

                # Check for duplicate placeholders
                if (defined $holders->{ lc($placeholder) }) {
                        $self->_fatal(
                                      sprintf("Duplicate placeholder '%s' found.  " . "Remember, placeholders are case-INsensitive",
                                              $placeholder
                                      ));
                } else {
                        $holders->{ lc($placeholder) } = 1;
                }

        }

        return 1;

}          # _placeholderValidate()

##
# Getter/Setter for user name

sub _userName
{

        my $self = shift;

        # Should {_userName} be already cached, then return it,
        # otherwise get the user name, cache it, and return
        if (defined $self->{_userName} and $self->{_userName} =~ /\w/) {
                return $self->{_userName};
        } elsif ($self->{use_effective_id}) {
                $self->{_userName} =
                    ($^O eq "MSWin32")
                    ? $ENV{EUID}   || 0
                    : getpwuid($>) || "nobody";
        } else {
                $self->{_userName} = getlogin() || getpwuid($<) || "nobody";
        }

        return $self->{_userName};

}          # _userName()

=head1 MICROSOFT WINDOWS CAVEATS

Under Microsoft Windows operating systems (WinXP, Win2003, Vista,
Win7, etc.), Log::Fine::Formatters::Template will use the following
environment variables for determining user and group information:

=over

=item * C<$UID>

=item * C<$EUID>

=item * C<$GID>

=item * C<$EGID>

=back

Under MS Windows, these values will invariably be set to 0.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-log-fine at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Fine>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Fine

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Fine>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Fine>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Fine>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Fine>

=back

=head1 AUTHOR

Christopher M. Fuhrman, C<< <cfuhrman at pobox.com> >>

=head1 SEE ALSO

L<perl>, L<Log::Fine::Formatter>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010-2011, 2013 Christopher M. Fuhrman, 
All rights reserved.

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;          # End of Log::Fine::Formatter::Template

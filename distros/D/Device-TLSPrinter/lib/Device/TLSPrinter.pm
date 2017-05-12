package Device::TLSPrinter;
use strict;
use Carp;
use Class::Accessor;
use Exporter ();

{
    no strict "vars";
    $VERSION = '0.51';
    @ISA = qw< Exporter Class::Accessor >;

    %EXPORT_TAGS = (
        feedback => [qw<
            FC_OK  FC_SERIAL_TIMEOUT_ERROR  FC_COMMAND_ERROR
            FC_MEMORY_FULL_ERROR  FC_IMAGE_ALREADY_EXISTS
            FC_IMMEDIATE_COMMANDS_ENABLED  FC_OUT_OF_LABELS  FC_PRINTHEAD_OPEN
            FC_OUT_OF_RIBBON  FC_BATTERY_CELL_SHORTED  FC_LOW_BATTERY
            FC_PRINTING_COMPLETE  FC_PRINTING_COMPLETE  FC_NO_LABEL_FORMAT_ERROR
            FC_MEMORY_READ_ERROR  FC_MEDIA_CHANGED  FC_PRINTHEAD_TOO_HOT
            FC_LABEL_ERROR  FC_FIELD_ERROR  FC_FEED_TO_CUT_COMPLETE

            FC_UNDEF FC_IMMEDIATE_COMMANDS_DISABLED  FC_NOT_IN_LABEL_EDIT_MODE

            ROTATION_NONE  ROTATION_90  ROTATION_180  ROTATION_270

            TYPE_FONT  TYPE_BARCODE_39  TYPE_BARCODE_39_WITH_CHECK 
            TYPE_BARCODE_128  TYPE_IMAGE
        >],
        ascii => [qw<
            SOH  STX  CR
        >],
    );

    $EXPORT_TAGS{all} = [ @{$EXPORT_TAGS{feedback}}, @{$EXPORT_TAGS{ascii}} ];
    @EXPORT = ( @{$EXPORT_TAGS{feedback}} );
    @EXPORT_OK = ( @{$EXPORT_TAGS{ascii}} );
}


# ASCII constants
use constant {
    SOH    => "\x01",
    STX    => "\x02",
    CR     => "\x0D",
    CRLF   => "\x0D\x0A",
    LF     => "\x0A",
};

use constant {
    # standard feedback chars
    FC_OK                           => "0",
    FC_SERIAL_TIMEOUT_ERROR         => "1",
    FC_COMMAND_ERROR                => "2",
    FC_MEMORY_FULL_ERROR            => "3",
    FC_IMAGE_ALREADY_EXISTS         => "4",
    FC_IMMEDIATE_COMMANDS_ENABLED   => "5",
    FC_OUT_OF_LABELS                => "6",
    FC_PRINTHEAD_OPEN               => "7",
    FC_OUT_OF_RIBBON                => "8",
    FC_BATTERY_CELL_SHORTED         => "A",
    FC_LOW_BATTERY                  => "B",
    FC_PRINTING_COMPLETE            => "C",
    FC_NO_LABEL_FORMAT_ERROR        => "D",
    FC_MEMORY_READ_ERROR            => "E",
    FC_MEDIA_CHANGED                => "F",
    FC_PRINTHEAD_TOO_HOT            => "G",
    FC_LABEL_ERROR                  => "H",
    FC_FIELD_ERROR                  => "I",
    FC_FEED_TO_CUT_COMPLETE         => "J",

    # custom feedback chars
    FC_UNDEF                        => "~",
    FC_IMMEDIATE_COMMANDS_DISABLED  => ";",
    FC_NOT_IN_LABEL_EDIT_MODE       => ":",

    # rotations
    ROTATION_NONE                   => 1,
    ROTATION_90                     => 2,
    ROTATION_180                    => 3,
    ROTATION_270                    => 4,

    # field types
    TYPE_FONT                       => "9",
    TYPE_BARCODE_39                 => "a",
    TYPE_BARCODE_39_WITH_CHECK      => "b",
    TYPE_BARCODE_128                => "c",
    TYPE_IMAGE                      => "Y",
};

# object fields and default values
my %object_fields = (
    # internal parameters
    _device         => undef,   # device string
    _socket         => undef,   # IO::Socket::INET object
    _serial         => undef,   # {Device,Win32}::SerialPort object
    _timeout        => 10,      # timeout

    # public attributes
    feedback_chars  => 0,   # are feedback characters enabled?
    immediate_cmds  => 0,   # are immediate commands enabled?
    label_edition   => 0,   # currently in label editing mode?
);

# create accessors
__PACKAGE__->mk_accessors(keys %object_fields);

# private variables
my $HEX = "[0-9A-Fa-f]";
my $HEXNUM = $HEX x 2;


#
# new()
# ---
sub new {
    my ($class, %args)  = @_;

    # if missing, try to infer the type from the device param
    if (not $args{type}) {
        if (eval { $args{device}->isa("Device::SerialPort") } ) {
            $args{type} = "serial"
        }
        elsif (eval { $args{device}->isa("Win32::SerialPort") } ) {
            $args{type} = "serial"
        }
        elsif ($args{device} =~ m{^COM\d|^/dev/(?:term|tty)}) {
            $args{type} = "serial"
        }
        elsif ($args{device} =~ m{^[a-zA-Z0-9.-]+:[0-9]+$}) {
            $args{type} = "network"
        }
    }

    # enable debug mode?
    {   local $SIG{__WARN__} = sub {};
        *DEBUG = $args{debug} ? \&_DEBUG : sub {};
    }

    # check arguments
    carp "warning: You should specify the connection type" unless exists $args{type};
    croak "error: Missing required parameter: device" unless exists $args{device};

    # create the object and populate the attributes
    my %fields = (
        %object_fields,     # default values
        _type    => $args{type}, 
        _device  => $args{device},
        _timeout => $args{timeout},
    );
    my $self = __PACKAGE__->SUPER::new(\%fields);

    # initialize the backend driver
    my ($driver) = $args{type} =~ /^(\w+)$/;
    $class = __PACKAGE__."::".ucfirst($driver);
    eval "require $class"
        or croak "error: Could not load driver $class: no such module";
    bless $self, $class;    # rebless the object into the class of the driver
    $self->init();

    return $self
}


#
# _DEBUG()
# ------
sub _DEBUG {
    print STDERR @_, $/
}


#
# exec_command()
# ------------
sub exec_command {
    my ($self, %args) = @_;
    my ($rc, $answer, $n) = (FC_UNDEF, "", 0);

    carp "error: Missing required parameter: cmd" and return unless $args{cmd};

    # send the data
    $n = $self->write(data => $args{cmd});

    # read the answer if any is expected
    if ($args{expect}) {
        my ($left_to_read, $read, $chunk);
        $left_to_read = $args{expect};

        while ($left_to_read > 0) {
            ($read, $chunk) = $self->read(expect => $left_to_read);
            $answer .= $chunk;
            $left_to_read -= $read;
        }
    }

    # read the feedback character if enabled
    if ($args{feedback} and $self->feedback_chars) {
        ($n, $rc) = $self->read(expect => 1);
        DEBUG(" >>> exec_command(): feedback='$rc' (", ord($rc), ")");
    }

    return ($rc, $answer)
}


# ========================================================================
# Immediate commands
#

my %ic_cmds = (
    ic_printer_reset    => { string => "#",  expect => 25 },
    ic_printer_status   => {
        string => "A",  expect =>  9,  filter => \&ic_filter_printer_status
    },
    ic_toggle_pause     => { string => "B",  expect =>  0 },
    ic_cancel_job       => { string => "C",  expect =>  0 },
    ic_batch_quantity   => { string => "E",  expect =>  5 },
);

for my $cmd (keys %ic_cmds) {
    no strict 'refs';
    *$cmd = sub {
        my ($self) = @_;
        my ($rc, $raw, @data) = (FC_UNDEF);
        DEBUG(" >>> $cmd()");

        if ($self->immediate_cmds) {
            ($rc, $raw) = $self->exec_command(
                cmd      => SOH.$ic_cmds{$cmd}{string}, 
                expect   => $ic_cmds{$cmd}{expect},
                feedback => 0, 
            );
            $rc = FC_OK;

            # pass the raw result to the filter if it's defined
            if (defined $raw and ref $ic_cmds{$cmd}{filter} eq "CODE") {
                @data = $ic_cmds{$cmd}{filter}->($raw)
            }
        }
        else {
            $rc = FC_IMMEDIATE_COMMANDS_DISABLED
        }

        return wantarray ? ($rc, $raw, @data) : $rc
    }
}


#
# ic_disable_immediate_cmds()
# -------------------------
sub ic_disable_immediate_cmds {
    my ($self) = @_;
    $self->exec_command(cmd => SOH."D");
    $self->immediate_cmds(0);
}


#
# ic_filter_printer_status()
# ------------------------
sub ic_filter_printer_status {
    my ($raw) = @_;

    # decode the status
    my @chars = split //, $raw;
    my %status = (
        printhead_open   => $chars[0] eq "Y" ? 1 : 0,
        out_of_labels    => $chars[1] eq "Y" ? 1 : 0,
        out_of_ribbon    => $chars[2] eq "Y" ? 1 : 0,
        printing_batch   => $chars[3] eq "Y" ? 1 : 0,
        busy_printing    => $chars[4] eq "Y" ? 1 : 0,
        printer_paused   => $chars[5] eq "Y" ? 1 : 0,
        touch_cell_error => $chars[6] eq "Y" ? 1 : 0,
        low_battery      => $chars[7] eq "Y" ? 1 : 0,
    );

    return %status
}


# ========================================================================
# System commands
#

my %sc_cmds = (
    sc_heat_setting_offset          => { string => "b%+02.2d" },
    sc_disable_feed_to_cut_position => { string => "C" },
    sc_enable_feed_to_cut_position  => { string => "c" },
    sc_quantity_for_stored_labels   => { string => "E%04d" },
    sc_form_feed                    => { string => "F" },
    sc_set_form_stop_position       => { string => "f%+02.2d" },
    sc_print_last_label_format      => { string => "G" },
    sc_set_printer_to_metric        => { string => "m" },
    sc_set_printer_to_inches        => { string => "n" },
    sc_set_start_of_print_offset    => { string => "O+02.2d" },
    sc_set_horizontal_align_offset  => { string => "o+02.2d" },
    sc_set_continuous_label_length  => { string => "P%04d" },
    sc_clear_all_memory             => { string => "Q" },
    sc_set_continuous_label_spacing => { string => "S%04d" },
    sc_print_test_label             => { string => "T" },
    sc_get_touch_cell_data_binary   => {
        string => "t",  expect => 32
    },
    sc_replace_label_format_field   => { string => "U%02d%s".CR },
    sc_get_touch_cell_data_ascii    => {
        string => "V",    expect => 32*2,  filter => \&sc_filter_touch_cell_data_ascii
    },
    sc_firmware_version             => {
        string => "v",    expect => 25,    filter => \&sc_filter_chomp
    },
    sc_memory_information           => { 
        string => "W%s",  expect => 255,   filter => \&sc_filter_memory_info
    },
    sc_delete_file                  => { string => "x%s%s" },
    sc_pack_memory                  => { string => "z" },
);

for my $cmd (keys %sc_cmds) {
    no strict 'refs';
    *$cmd = sub {
        my ($self, @args) = @_;
        my @data;
        DEBUG(" >>> $cmd(@args)");

        # execute the command
        my ($rc, $raw) = $self->exec_command(
            cmd      => sprintf(STX.$sc_cmds{$cmd}{string}, @args),
            expect   => $sc_cmds{$cmd}{expect}, 
            feedback => 1,
        );

        # pass the raw result to the filter if it's defined
        if (defined $raw and ref $sc_cmds{$cmd}{filter} eq "CODE") {
            @data = $sc_cmds{$cmd}{filter}->($raw)
        }

        return wantarray ? ($rc, $raw, @data) : $rc
    }
}


#
# sc_filter_chomp()
# ---------------
sub sc_filter_chomp {
    my ($raw) = @_;
    $raw =~ s/[\012\015]$//g;
    return $raw
}


#
# sc_filter_memory_info()
# ---------------------
sub sc_filter_memory_info {
    my ($raw) = @_;
    $raw =~ s/\b($HEX+)\s$/hex($1)/e;
    return split CR, $raw
}


#
# sc_filter_touch_cell_data_ascii()
# -------------------------------
sub sc_filter_touch_cell_data_ascii {
    my ($raw) = @_;

    my @values = map {hex} $raw =~ m{
        ^ $HEXNUM ($HEXNUM $HEXNUM) $HEXNUM $HEXNUM     # label quantity
        ($HEXNUM) ($HEXNUM $HEXNUM) ($HEXNUM $HEXNUM)   # bits field, offset X and Y
        ($HEXNUM $HEXNUM) ($HEXNUM $HEXNUM)             # width, length
    }x;

    my %fields = (
        remaining_labels => $values[0],
        notched_material => $values[1] & 1,
        offset_x         => $values[2],
        offset_y         => $values[3],
        label_width      => $values[4],
        label_length     => $values[5],
    );

    return %fields
}


#
# sc_disable_feedback_chars()
# -------------------------
## @method string sc_disable_feedback_chars($self)
# @return feedback code
#
sub sc_disable_feedback_chars {
    my ($self) = @_;
    DEBUG(" >>> sc_disable_feedback_chars()");
    $self->exec_command(cmd => STX."A", feedback => 0);
    $self->feedback_chars(0);
}


#
# sc_enable_feedback_chars()
# ------------------------
## @method string sc_enable_feedback_chars($self)
# @return feedback code
#
sub sc_enable_feedback_chars {
    my ($self) = @_;
    DEBUG(" >>> sc_enable_feedback_chars()");
    $self->exec_command(cmd => STX."a", feedback => 0);
    $self->feedback_chars(1);
}


#
# sc_enable_immediate_cmds()
# ------------------------
## @method string sc_enable_immediate_cmds($self)
# @return feedback code
#
*ic_enable_immediate_cmds = \&sc_enable_immediate_cmds;
sub sc_enable_immediate_cmds {
    my ($self) = @_;
    DEBUG(" >>> sc_enable_immediate_cmds()");
    my ($rc) = $self->exec_command(cmd => STX."H", feedback => 1);
    $self->immediate_cmds(1) if $rc eq FC_IMMEDIATE_COMMANDS_ENABLED;
    return $rc
}


#
# sc_input_image_data()
# -------------------
## @method string sc_input_image_data($self, $data_type, $format, $image_name, @image_data)
# @param data_type string
# @param format string, image format designation
# @param image_name string, image name, up to 8 characters long
# @param image_data array or image data
# @return feedback code
#
sub sc_input_image_data {
    my ($self, $data_type, $format, $image_name, @image_data) = @_;
    DEBUG(" >>> sc_input_image_data($data_type, $format, $image_name)");

    # check arguments
    carp "error: Invalid value for data type: '$data_type'"
        and return if $data_type !~ /^[AB]$/;
    carp "error: Invalid value for format designation: '$format'"
        and return if $format !~ /^[BbPpU]$/;

    # first disable immediate commands if they were enabled
    my $ic_enabled = $self->immediate_cmds;
    $self->ic_disable_immediate_cmds if $ic_enabled;

    # then send the actual image command
    my $cmd  = sprintf STX."I%s%s%s".CR, $data_type, $format, $image_name;
    my $data = join '', @image_data;
    my ($rc) = $self->exec_command(cmd => $cmd.$data, feedback => 1);

    # finaly restore immediate commands
    $self->sc_enable_immediate_cmds if $ic_enabled;

    return $rc
}


#
# sc_extended_system_cmds()
# -----------------------
## @method string sc_extended_system_cmds($self)
# @return feedback code
#
sub sc_extended_system_cmds {
    my ($self) = @_;
    DEBUG(" >>> sc_extended_system_cmds()");
    $self->exec_command(cmd => STX."K", feedback => 0);
}


#
# sc_enter_label_formatting_cmd()
# -----------------------------
## @method string sc_enter_label_formatting_cmd($self)
# @return feedback code
#
sub sc_enter_label_formatting_cmd {
    my ($self) = @_;
    DEBUG(" >>> sc_enter_label_formatting_cmd()");

    my ($rc) = $self->exec_command(cmd => STX."L", feedback => 1);
    $self->label_edition(1);

    return $rc
}


# ========================================================================
# Label formatting commands
#

my %lc_cmds = (
    lc_set_format_attribute             => { string => "A%d".CR },
    lc_set_column_offset                => { string => "C%04d".CR },
    lc_end_label_formatting_and_print   => { string => "E".CR,  end_mode => 1 },
    lc_set_row_offset                   => { string => "C%04d".CR },
    lc_end_label_formatting             => { string => "X".CR,  end_mode => 1 },
    lc_increment_prev_numeric_field     => { string => "+%s%02d".CR },
    lc_decrement_prev_numeric_field     => { string => "-%s%02d".CR },
    lc_increment_prev_alphanum_field    => { string => ">%s%02d".CR },
    lc_decrement_prev_alphanum_field    => { string => "<%s%02d".CR },
    lc_set_count_by_amount              => { string => "^%02d".CR },
    lc_add_field                        => { string => "%d%s00%03d%04d%04d".CR },
);

for my $cmd (keys %lc_cmds) {
    no strict 'refs';
    *$cmd = sub {
        my ($self, @args) = @_;
        DEBUG(" >>> $cmd(@args)");

        # check that we're in label formatting mode
        return FC_NOT_IN_LABEL_EDIT_MODE
            unless $self->label_edition;

        # execute the command
        my ($rc) = $self->exec_command(
            cmd      => sprintf($lc_cmds{$cmd}{string}, @args),
            expect   => $lc_cmds{$cmd}{expect}, 
            feedback => 1,
        );

        # end edition mode if needed
        if ($lc_cmds{$cmd}{end_mode}) {
            $self->label_edition(0)
        }

        return $rc
    }
}


# ========================================================================
# High-level commands
#


#
# hc_flush_input()
# --------------
## @method string hc_flush_input($self)
# @return feedback code
#
sub hc_flush_input {
    my ($self) = @_;
    my ($n, $data) = (1, "");

    # read everything in the input buffer
    while ($n) {
        local $SIG{ALRM} = sub { $n = 0; die "read timeout\n" };
        alarm 2;
        ($n, $data) = eval { $self->read(expect => 20) };
        alarm 0;
        $n ||= 0;
    }

    return FC_OK
}


#
# hc_upload_label()
# ---------------
## @method string hc_upload_label($self, %params)
# @param lines arrayref of lines describing the label
# @param print_now boolean
# @return feedback code
#
sub hc_upload_label {
    my ($self, %args) = @_;
    DEBUG(" >>> hc_upload_label()");
    my $rc;
    croak "error: Missing required parameter: lines" unless exists $args{lines};
    croak "error: Invalid value for parameter 'lines'" unless ref $args{lines} eq "ARRAY";

    # prepare the data to be sent
    my @lines = @{ $args{lines} };
    chomp @lines;

    # send the label data
    $self->sc_enter_label_formatting_cmd;

    for my $line (@lines) {
        ($rc) = $self->exec_command(cmd => $line.CR, feedback => 1);
        last if $rc ne FC_OK;
    }

    # in case of error, stop and return the last feedback char
    if ($rc ne FC_OK) {
        $self->lc_end_label_formatting;
        return $rc
    }

    # end the label edition mode
    if ($args{print_now}) {
        ($rc) = $self->lc_end_label_formatting_and_print
    }
    else {
        ($rc) = $self->lc_end_label_formatting
    }

    return $rc
}


1;

__END__

=head1 NAME

Device::TLSPrinter - Module for using a TLS barcode printer

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Device::TLSPrinter;

    # use a printer connected to the serial port
    my $printer = Device::TLSPrinter->new(type => "serial", device => "/dev/ttyS0");

    # use a printer connected to the serial port, reusing an 
    # existing Device::SerialPort or Win32::SerialPort object
    my $printer = Device::TLSPrinter->new(device => $serial_device);

    # connect to a printer shared by network
    my $printer = Device::TLSPrinter->new(type => "network", device => "host:port");


=head1 DESCRIPTION

This module is a driver for the TLS PC Link thermal labeling printer.
It implements the commands from the Datamax Programming Language (DPL)
recognized by the TLS PC Link printer.


=head1 FUNCTIONS

=head2 General methods

=head3 new()

Create and return a new object. 

B<Parameters>

=over

=item *

C<type> - specify the type of connection, either C<serial> or C<network>

=item *

C<device> - I<(mandatory)> specify a device name or path to use, 
or the host and port to connect to (depending on the connection type)

=back


=head3 exec_command()

Transmit a command to the printer.

B<Parameters>

=over

=item *

C<cmd> - I<(mandatory)> command string to send

=item *

C<expect> - if the command expects an answer, indicate the number 
of characters to read

=back

=cut


=head2 Attributes

=head3 feedback_chars()

Returns true if feedback characters are enabled.

=head3 immediate_cmds()

Returns true if immediate commands are enabled.

=head3 label_edition()

Returns true if currently in label editing mode.


=head2 Immediate commands

=head3 ic_printer_reset()

Reset the printer: return all settings to the default, clear all 
buffers and the internal RAM. Return the firmware version.
See [TLS-PG] p.7


=head3 ic_printer_status()

Fetch and returns the printer status.
See [TLS-PG] p.8

B<Returns>

=over

=item *

feedback code

=item 

raw printer status as a string

=item 

decoded printer status as a hash

=back

B<Example>

    my ($rc, $raw, %status) = $device->ic_printer_status()


=head3 ic_toggle_pause()

Pause or resume the current print job.
See [TLS-PG] p.9


=head3 ic_cancel_job()

Cancel the current print job.
See [TLS-PG] p.10


=head3 ic_disable_immediate_cmds()

Disable immediate commands. They can be enabled again using 
C<sc_enable_immediate_cmds()>.
See [TLS-PG] p.10


=head3 ic_batch_quantity()

Fetch and return the quantity of label left to print in the current batch.
See [TLS-PG] p.10

B<Example>

    my ($rc, $qty) = $device->ic_batch_quantity()


=head2 System commands

=head3 sc_disable_feedback_chars()

Disable feedback characters.
See [TLS-PG] p.12


=head3 sc_enable_feedback_chars()

Enable feedback characters.
See [TLS-PG] p.12


=head3 sc_heat_setting_offset()

Adjust the time during which the dots on the printhead are heated.
See [TLS-PG] p.13

B<Arguments>

=over

=item 1.

time offset in hundreds of microseconds; valid range is -5 to -5

=back


=head3 sc_disable_feed_to_cut_position()

See [TLS-PG] p.13


=head3 sc_enable_feed_to_cut_position()

See [TLS-PG] p.14


=head3 sc_quantity_for_stored_labels()

Set the quantity of labels to print using the current label format.
See [TLS-PG] p.14

B<Arguments>

=over

=item 1.

number of labels to print

=back

=head3 sc_form_feed()

Feed one label to the top of form.
See [TLS-PG] p.15


=head3 sc_set_form_stop_position()

Adjust the cutter stop position.
See [TLS-PG] p.15

=over

=item 1.

offest in pixels; valid range is -8 to +8

=back

=head3 sc_print_last_label_format()

Print the label format currently in memory.
See [TLS-PG] p.16


=head3 sc_enable_immediate_cmds()

Enable immediate commands.
See [TLS-PG] p.16


=head3 sc_input_image_data()

Upload an image from the host to the printer.
See [TLS-PG] p.17

B<Arguments>

=over

=item 1.

data type, C<"A"> for ASCII, C<"B"> for binary

=item 2.

image format designation

=item 3.

image name, up to 8 characters long

=item 4.

image data

=back


=head3 sc_extended_system_cmds()

Enable extended system commands.
See [TLS-PG] p.18


=head3 sc_enter_label_formatting_cmd()

Enter label formatting mode. See L<"Label formatting commands">.
See [TLS-PG] p.18


=head3 sc_set_printer_to_metric()

Set the printer to use the metric system for measurements.
See [TLS-PG] p.18


=head3 sc_set_printer_to_inches()

Set the printer to use the imperial system for measurements.
See [TLS-PG] p.19


=head3 sc_set_start_of_print_offset()

Adjust the point where printing starts, relative to the top-of-form
position.
See [TLS-PG] p.19

B<Arguments>

=over

=item 1.

offset in pixels, valid range is -5 to +99

=back


=head3 sc_set_horizontal_align_offset()

Adjust the point where printing starts, relative to the left edge of 
the label.
See [TLS-PG] p.20

B<Arguments>

=over

=item 1.

offset in pixels, valid range is -5 to +99

=back


=head3 sc_set_continuous_label_length()

Set the label length for continuous material.
See [TLS-PG] p.20

B<Arguments>

=over

=item 1.

label length, valid range is 0.0 to 152.4 mm, or 0.0 to 6.0 inches

=back


=head3 sc_clear_all_memory()

Instruct the printer to clear all images from memory.
See [TLS-PG] p.21


=head3 sc_set_continuous_label_spacing()

Set the label spacing for continuous material.
See [TLS-PG] p.21

B<Arguments>

=over

=item 1.

label spacing, in current measurement unit

=back


=head3 sc_print_test_label()

Instruct the printer to print a dot pattern test label.
See [TLS-PG] p.22


=head3 sc_get_touch_cell_data_binary

Fetch and return the touch cell data from the media as binary.
See [TLS-PG] p.22

B<Returns>

=over

=item *

feedback code

=item *

raw cell status as binary

=back


=head3 sc_replace_label_format_field

Place new data into format fields.
See [TLS-PG] p.24

B<Arguments>

=over

=item 1.

format field number

=item 2.

new string data

=back


=head3 sc_get_touch_cell_data_ascii

Fetch and return the touch cell data from the media as ASCII.
See [TLS-PG] p.25

B<Returns>

=over

=item *

feedback code

=item *

raw cell status as a string

=item *

decoded cell status as a hash

=back

B<Example>

    my ($rc, $raw, %stat) = $device->sc_get_touch_cell_data_ascii


=head3 sc_firmware_version()

Fetch and return the firmware version.
See [TLS-PG] p.25


=head3 sc_memory_information()

Fetch and return a directory listing of images in printer memory.
See [TLS-PG] p.25


=head3 sc_delete_file()

Instruct the printer to remove a specific file from memory.
See [TLS-PG] p.26

B<Arguments>

=over

=item 1.

file type, C<"G"> for image

=item 2.

file name

=back

=head3 sc_pack_memory()

Instruct the printer to reclaim all storage space associated with deleted files.
See [TLS-PG] p.27


=head2 Label formatting commands

=head3 lc_set_format_attribute()

See [TLS-PG] p.30

B<Arguments>

=over

=item 1.

mode

=back


=head3 lc_set_column_offset()

See [TLS-PG] p.31

B<Arguments>

=over

=item 1.

column offset

=back


=head3 lc_end_label_formatting_and_print()

See [TLS-PG] p.31


=head3 lc_set_row_offset()

See [TLS-PG] p.31

B<Arguments>

=over

=item 1.

row offset

=back


=head3 lc_end_label_formatting()

See [TLS-PG] p.32


=head3 lc_increment_prev_numeric_field()

See [TLS-PG] p.33

B<Arguments>

=over

=item 1.

fill char

=item 2.

increment amount

=back


=head3 lc_decrement_prev_numeric_field()

See [TLS-PG] p.33

B<Arguments>

=over

=item 1.

fill char

=item 2.

increment amount

=back


=head3 lc_increment_prev_alphanum_field()

See [TLS-PG] p.34

B<Arguments>

=over

=item 1.

fill char

=item 2.

increment amount

=back


=head3 lc_decrement_prev_alphanum_field()

See [TLS-PG] p.34

B<Arguments>

=over

=item 1.

fill char

=item 2.

increment amount

=back


=head3 lc_set_count_by_amount()

See [TLS-PG] p.35

B<Arguments>

=over

=item 1.

number of labels before incrementing or decrementing

=back


=head3 lc_add_field()

See [TLS-PG] p.37

B<Arguments>

=over

=item 1.

rotation, see ROTATION_*

=item 2.

type of field, see TYPE_*

=item 3.

font size / barcode height

=item 4.

row

=item 5.

column

=back


=head2 High-level commands

=head3 hc_flush_input()

Flush the input buffers. Must typically be used when the printer is power 
cycled.


=head3 hc_upload_label()

Transfer a label onto the printer, optionally asking for immediate printing.

See [TLS-PG] pp.29-43

B<Parameters>

=over

=item *

C<lines> - I<(mandatory)> arrayref of lines describing the label

=item *

C<print_now> - prints the label now if given a true value; defaults to false

=back

B<Return>

=over

=item 1.

feedback code

=back


=head1 CONSTANTS

C<Device::TLSPrinter> defines the following constants.

=head2 Feedback codes

Most system and label formatting commands return the feedback character as 
result code. See [TLS-PG] pp.12, 47

=over

=item *

C<FC_OK> - no error

=item *

C<FC_SERIAL_TIMEOUT_ERROR> - serial timeout error

=item *

C<FC_COMMAND_ERROR> - command error

=item *

C<FC_MEMORY_FULL_ERROR> - memory full error

=item *

C<FC_IMAGE_ALREADY_EXISTS> - image already exists in memory so it was not stored

=item *

C<FC_IMMEDIATE_COMMANDS_ENABLED> - immediate commands enabled

=item *

C<FC_OUT_OF_LABELS> - out of labels

=item *

C<FC_PRINTHEAD_OPEN> - printhead open

=item *

C<FC_OUT_OF_RIBBON> - out of ribbon

=item *

C<FC_BATTERY_CELL_SHORTED> - battery cell is shorted

=item *

C<FC_LOW_BATTERY> - low battery

=item *

C<FC_PRINTING_COMPLETE> - printing is complete

=item *

C<FC_NO_LABEL_FORMAT_ERROR> - did not print because no label format has been given

=item *

C<FC_MEMORY_READ_ERROR> - error reading memory touch cell on media

=item *

C<FC_MEDIA_CHANGED> - media has changed

=item *

C<FC_PRINTHEAD_TOO_HOT> - printhead is too hot

=item *

C<FC_LABEL_ERROR> - error building label

=item *

C<FC_FIELD_ERROR> - field error

=item *

C<FC_FEED_TO_CUT_COMPLETE> - feed to cut complete

=back

The following errors are specific to C<Device::TLSPrinter>.

=over

=item *

C<FC_UNDEF> - default value when no feedback was available (typically 
for immediate commands)

=item *

C<FC_IMMEDIATE_COMMANDS_DISABLED> - confirms that immediate commands were 
disabled

=item *

C<FC_NOT_IN_LABEL_EDIT_MODE> - a label formatting command was requested 
while not in label formatting mode

=back

=head2 Rotations

Available rotations for C<lc_add_field()>.

=over

=item *

C<ROTATION_NONE> - no rotation

=item *

C<ROTATION_90> - rotate by 90E<deg>

=item *

C<ROTATION_180> - rotate by 180E<deg>

=item *

C<ROTATION_270> - rotate by 270E<deg>

=back

=head2 Field types

Available field types for C<lc_add_field()>.

=over

=item *

C<TYPE_FONT> - font

=item *

C<TYPE_BARCODE_39> - barcode in Code 39

=item *

C<TYPE_BARCODE_39_WITH_CHECK> - barcode in Code 39 with check character

=item *

C<TYPE_BARCODE_128> - barcode in Code 128

=item *

C<TYPE_IMAGE> - image file

=back


=head1 DIAGNOSTICS

=over

=item C<Could not load driver %s: no such module>

B<(E)> The indicated driver could be be loaded. Please check the argument 
given to the parameter C<type> given to C<new()>.

=item C<Invalid value for %s>

B<(E)> The value passed to the indicated parameter is not valid. 
Please check the documentation of the corresponding function for the 
valid values.

=item C<Missing required parameter: %s>

B<(E)> The indicated parameter is mandatory, but you didn't provide an 
arugment for it. Please check the documentation of the corresponding 
function.

=item C<You should specify the connection type>

B<(W)> You didn't set the C<type> parameter for C<new()>. The function 
then tries to guess the correct type.

=back


=head1 SEE ALSO

[TLS-PG] I<TLS PC Link Programmer's Guide>,
L<http://www.bradyid.com/bradyid/downloads/downloadsPageView.do?file=TLSPCLink_Prog.pdf>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-device-tlsprinter at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Dist/Display.html?Name=Device-TLSPrinter>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::TLSPrinter

You can also look for information at:

=over

=item * MetaCPAN

L<https://metacpan.org/module/Device::TLSPrinter>

=item * Search CPAN

L<http://search.cpan.org/dist/Device-TLSPrinter>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Device-TLSPrinter>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Dist/Display.html?Name=Device-TLSPrinter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Device-TLSPrinter>

=back


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, C<< <sebastien (at) aperghis.net> >>


=head1 COPYRIGHT & LICENSE

Copyright 2006-2012 SE<eacute>bastien Aperghis-Tramoni, all rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


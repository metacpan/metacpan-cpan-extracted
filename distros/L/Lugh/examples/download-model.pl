#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use File::Path qw(make_path);
use Getopt::Long;

=head1 NAME

download-model.pl - Download GGUF models for use with Lugh

=head1 SYNOPSIS

    # Download default model (TinyLlama Q4_K_M)
    perl examples/download-model.pl

    # Download specific model
    perl examples/download-model.pl --model tinyllama-q2

    # List available models
    perl examples/download-model.pl --list

    # Download to custom directory
    perl examples/download-model.pl --dir /path/to/models

=head1 DESCRIPTION

This script downloads pre-quantized GGUF model files from Hugging Face
for use with Lugh. These are small models suitable for testing and
development.

=cut

# Available models (small ones suitable for testing)
my %MODELS = (
    'tinyllama-q2' => {
        url  => 'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q2_K.gguf',
        file => 'tinyllama-1.1b-chat-v1.0.Q2_K.gguf',
        size => '460MB',
        desc => 'TinyLlama 1.1B Chat - Q2_K quantization (smallest)',
    },
    'tinyllama-q4' => {
        url  => 'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
        file => 'tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
        size => '637MB',
        desc => 'TinyLlama 1.1B Chat - Q4_K_M quantization (recommended)',
    },
    'phi2-q4' => {
        url  => 'https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf',
        file => 'phi-2.Q4_K_M.gguf',
        size => '1.6GB',
        desc => 'Microsoft Phi-2 2.7B - Q4_K_M quantization',
    },
    'qwen2-0.5b-q4' => {
        url  => 'https://huggingface.co/Qwen/Qwen2-0.5B-Instruct-GGUF/resolve/main/qwen2-0_5b-instruct-q4_k_m.gguf',
        file => 'qwen2-0_5b-instruct-q4_k_m.gguf',
        size => '400MB',
        desc => 'Qwen2 0.5B Instruct - Q4_K_M quantization (tiny)',
    },
);

my $DEFAULT_MODEL = 'tinyllama-q4';

# Parse options
my $model_name = $DEFAULT_MODEL;
my $output_dir = 'models';
my $list_models = 0;
my $help = 0;

GetOptions(
    'model|m=s' => \$model_name,
    'dir|d=s'   => \$output_dir,
    'list|l'    => \$list_models,
    'help|h'    => \$help,
) or usage();

usage() if $help;

if ($list_models) {
    print "Available models:\n\n";
    for my $name (sort keys %MODELS) {
        my $m = $MODELS{$name};
        my $default = $name eq $DEFAULT_MODEL ? ' (default)' : '';
        printf "  %-20s %s%s\n", $name, $m->{size}, $default;
        printf "  %-20s %s\n", '', $m->{desc};
        print "\n";
    }
    exit 0;
}

# Validate model
unless (exists $MODELS{$model_name}) {
    die "Unknown model: $model_name\nUse --list to see available models.\n";
}

my $model = $MODELS{$model_name};
my $url = $model->{url};
my $filename = $model->{file};
my $output_path = "$output_dir/$filename";

# Create output directory
make_path($output_dir) unless -d $output_dir;

# Check if already downloaded
if (-f $output_path) {
    print "Model already exists: $output_path\n";
    print "Delete it first if you want to re-download.\n";
    exit 0;
}

print "Downloading: $model->{desc}\n";
print "Size: $model->{size}\n";
print "URL: $url\n";
print "Destination: $output_path\n\n";

# Try different download methods
my $success = 0;

# Try curl first
if (system_available('curl')) {
    print "Downloading with curl...\n";
    my $ret = system('curl', '-L', '-o', $output_path, '--progress-bar', $url);
    $success = ($ret == 0);
}
# Try wget
elsif (system_available('wget')) {
    print "Downloading with wget...\n";
    my $ret = system('wget', '-O', $output_path, '--show-progress', $url);
    $success = ($ret == 0);
}
# Try LWP::UserAgent
elsif (eval { require LWP::UserAgent; 1 }) {
    print "Downloading with LWP::UserAgent...\n";
    my $ua = LWP::UserAgent->new(
        timeout => 600,
        show_progress => 1,
    );
    my $response = $ua->get($url, ':content_file' => $output_path);
    $success = $response->is_success;
    unless ($success) {
        warn "Download failed: " . $response->status_line . "\n";
    }
}
else {
    die "No download method available. Install curl, wget, or LWP::UserAgent.\n";
}

if ($success && -f $output_path) {
    my $size = -s $output_path;
    printf "\nDownload complete: %s (%.1f MB)\n", $output_path, $size / (1024*1024);
    print "\nUsage example:\n";
    print "    use Lugh::Model;\n";
    print "    my \$model = Lugh::Model->load('$output_path');\n";
} else {
    unlink $output_path if -f $output_path;
    die "Download failed.\n";
}

sub system_available {
    my ($cmd) = @_;
    my $devnull = $^O eq 'MSWin32' ? 'NUL' : '/dev/null';
    return system("which $cmd > $devnull 2>&1") == 0;
}

sub usage {
    print <<"END";
Usage: $0 [options]

Options:
    -m, --model NAME    Model to download (default: $DEFAULT_MODEL)
    -d, --dir PATH      Output directory (default: models)
    -l, --list          List available models
    -h, --help          Show this help

Examples:
    $0                          # Download default model
    $0 --model tinyllama-q2     # Download smaller model
    $0 --list                   # List all available models

END
    exit 1;
}

__END__

=head1 MODELS

The following models are available:

=over 4

=item tinyllama-q2

TinyLlama 1.1B Chat with Q2_K quantization. Smallest option (~460MB).

=item tinyllama-q4 (default)

TinyLlama 1.1B Chat with Q4_K_M quantization. Good balance of size and quality (~637MB).

=item phi2-q4

Microsoft Phi-2 2.7B with Q4_K_M quantization. Higher quality, larger size (~1.6GB).

=item qwen2-0.5b-q4

Qwen2 0.5B Instruct with Q4_K_M quantization. Very small (~400MB).

=back

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

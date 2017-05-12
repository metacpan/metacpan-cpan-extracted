#!/usr/bin/perl

use strict;
use warnings;

use Hyper::Error;
use Getopt::Long;
use Pod::Usage;

GetOptions(
    'help|?'      => \my $help,
    man           => \my $man,
    force         => \my $force,
    'template!'   => \my $template,
    'code!'       => \my $code,
    'type=s'      => \my $type,
    'base_path=s' => \my $base_path,
    'verbose'     => \my $verbose,
    'usecase:s'   => \my $usecase,
    'service:s'   => \my $service,
    'class:s'     => \my $class,
    'namespace=s' => \my $namespace,
    'file=s'      => \my $file,
) or pod2usage(2);

if ( $help ) {
    pod2usage(1);
}
elsif ( $file ) {
    # split file in useable parts
    ($base_path, $namespace, $type, $service, $usecase)
        = $file =~ m{\A(.+?/)etc/([^/]+)/Control/([^/]+)/([^/]+)/(?: C|F)([^\.]+)\.ini\z}xms;

    # tell the user some details
    print "Error:\n     please check your file path layout\n"
        if 5 != grep {
               defined $_;
           } $base_path, $namespace, $type, $service, $usecase;
}

if ( ! $type || ! $base_path || ! $namespace ) {
    pod2usage(2);
}
elsif ( $man ) {
    pod2usage(-exitstatus => 0, -verbose => 2);
}

# handle verbose arg
$verbose or local $SIG{__WARN__} = sub {};

# fix type
$type = lc $type;
# create a new environment ?
if ( $type eq 'env' ) {
    require Hyper::Developer::Generator::Environment;
    Hyper::Developer::Generator::Environment->new({
        base_path => $base_path,
        namespace => $namespace,
        verbose   => $verbose,
        force     => $force,
    })->create();
}
else {
    # requires namespace and ( class, or (service and usecase) )

    my %class_for = qw(
        flow        Hyper::Developer::Generator::Control::Flow
        container   Hyper::Developer::Generator::Control::Container
    );
#        primitive   Hyper::Generator::Developer::Control::Primitive
#        base        Hyper::Generator::Developer::Control::Base
#    );
    if ( exists $class_for{$type} ) {
        eval "use $class_for{$type}";
        if ($@) {
            print "internal error >$@< may your \@INC path is broken";
            exit 1;
        }
        else {
            $class_for{$type}->new({
                force     => $force,
                base_path => $base_path,
                namespace => $namespace,
                service   => $service,
                usecase   => $usecase,
                verbose   => $verbose,
                template  => defined $template
                    ? $template
                    : 0,
                code      => defined $code
                    ? $code
                    : 1,
            })->create();
        }
    }
    else {
        print "don't know what to do with type >$type<";
        exit 1;
    }
}

if ( $file ) {
    print "Hyper code generation successful\n";
}

__END__

=pod

=head1 NAME

 hyper - generator for the Hyper Framework

=head1 SYNOPSIS

 hyper [options]

 Required Options:
   --namespace=s   namespace for your application
   --base_path=s   application base path
   --type=s        what to generate Container
 or only
   --file=s        config file which should be used for generation

 Options:
   --help          brief help message
   --man           brief documentation
   --verbose       more information
   --force         overwrite existing files
   --(no-)code     generate code?
   --(no-)template generate template?
   --service=s     your service
   --usecase=s     your usecase
   --class=s       not implemented

=head1 DESCRIPTION

 B<hyper> is for code, template and environment
 generation in the Hyper Framework.

=head1 OPTIONS

Arguments with an * are required.

=over

=item B<-help>

=item B<-man>

=item B<-verbose>

=item B<-force>

Overwrite existant files on generation.

=item B<-namespace>

Namespace of your Hyper application. 

=item B<-base>

base path of your application

=item B<-type>

specifies type of generation - valid types are

=over

=item env

=item container

=item flow

=item primitive

not implemented

=item base

not implemented

=back

=item B<-service>

Required for Flow and Container generation.

=item B<-usecase>

Required for Flow and Container generation.

=item B<-class>

not implemented

=item B<-template>

 default: false

=item B<-code>

 default: true

=back

=head2 SEE ALSO

L<Hyper::Developer::Manual::IDE>

=cut

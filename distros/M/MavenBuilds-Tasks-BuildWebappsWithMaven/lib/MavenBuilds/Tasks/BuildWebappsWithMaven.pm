package MavenBuilds::Tasks::BuildWebappsWithMaven;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Exporter qw(import);
our @EXPORT = qw(execute setOptions setTomcatDirectory setMavenDirectory setMavenArtifactsDirectory setLocationsOfLocalDependencies setWebAppLoc setMavenSettingsFileLocation);

use File::Path;
use XML::Simple;
use Data::Dumper;
use File::Copy::Recursive qw(dircopy);
use Getopt::Long;

#prefill default Locations
my $tomcatDir = "C:/Users/i076326/Documents/softwares/apache-tomcat-7.0.57/bin";
my $mavenDir = "C:/Users/i076326/Documents/softwares/apache-maven-3.0.5/bin";
my $mavenArtifactsDir = "C:/Users/i076326/.m2";
my @localDevVersions = ("C:/Users/i076326/git/sap.ui.m2m.extor.reuse");
my $webAppLoc = "C:/Users/i076326/git/ui.m2m.extor";
my $settingsFile = "settings-ui5.xml";

=head1 NAME

MavenBuilds::Tasks::BuildWebappsWithMaven - The great new MavenBuilds::Tasks::BuildWebappsWithMaven!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use MavenBuilds::Tasks::BuildWebappsWithMaven;

    my $foo = MavenBuilds::Tasks::BuildWebappsWithMaven->new();
    $foo->execute();

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
    
    my $self = {};
    bless($self);
    return $self;
}

=head2 setOptions

=cut

sub setOptions{
    
    my $localDevVersionsStr = 0;
    
    GetOptions(
        "tomcatDir=s", \$tomcatDir,
        "mavenDir=s", \$mavenDir,
        "mavenArtifactsDir=s", \$mavenArtifactsDir,
        "localDevVersions=s", \$localDevVersionsStr,
        "webAppLoc=s", \$webAppLoc,
        "settingsFile=s", \$settingsFile
    );
    
    @localDevVersions = split(",", $localDevVersionsStr, length($localDevVersionsStr));
}

=head2 setTomcatDirectory

=cut

sub setTomcatDirectory{
    $tomcatDir = $_[0];
}

=head2 setMavenDirectory

=cut

sub setMavenDirectory{
    $mavenDir = $_[0];
}

=head2 setMavenArtifactsDirectory

=cut

sub setMavenArtifactsDirectory{
    $mavenArtifactsDir = $_[0];
}

=head2 setLocationsOfLocalDependencies

=cut

sub setLocationsOfLocalDependencies{
    @localDevVersions = @_;
}

=head2 setWebAppLoc

=cut

sub setWebAppLoc{
    $webAppLoc = $_[0]; 
}

=head2 setMavenSettingsFileLocation

=cut

sub setMavenSettingsFileLocation{
    $settingsFile = $_[0];
}

=head2 execute

=cut

sub execute{
    _stopTomcat();
    _cleanupTomcatDirectory();
    _readAndCleanupLocalDependencies();
    _createNewSnapshots();
    _hostAndStart();
}

=head2 _stopTomcat

=cut

sub _stopTomcat{
    chdir $tomcatDir;
    my @argsTomcatStop = ("shutdown.bat");
    system(@argsTomcatStop);
    
    print "Stop Tomcat\n";
}

=head2 _startTomcat

=cut

sub _startTomcat{
    chdir $tomcatDir;
    my @argsTomcatStart = ("startup.bat");
    system(@argsTomcatStart);
}

=head2 _getArtifactIdOfParent

=cut

sub _getArtifactIdOfParent{
    my $fileName = $webAppLoc . "/pom.xml";
    my $xml = new XML::Simple;
    
    my $data = $xml->XMLin($fileName);
    
    my $webappGroupId = $data->{groupId};
    my $webappArtifactId = $data->{artifactId};
    
    return $webappArtifactId;
}

=head2 _getWebappDirectory

=cut

sub _getWebappDirectory{
    my $tomcatPathMaker = substr($tomcatDir, 0, -4);
    $tomcatPathMaker = $tomcatPathMaker . "/webapps";
    
    return $tomcatPathMaker;
}

=head2 _cleanupTomcatDirectory

=cut

sub _cleanupTomcatDirectory{
    my $tomcatPathMaker = _getWebappDirectory();
    my $webappArtifactId = _getArtifactIdOfParent();
    rmtree($tomcatPathMaker . "/" . $webappArtifactId, { verbose => 1, mode => 0711 });
}

=head2 _readAndCleanupLocalDependencies

=cut

sub _readAndCleanupLocalDependencies{
    for my $count (@localDevVersions){
        my $fileName = $count . "/pom.xml";
        my $xml = new XML::Simple;
    
        my $data = $xml->XMLin($fileName);
    
        my $groupId = $data->{groupId};
        my $artifactId = $data->{artifactId};
    
        my @pathFormer = split('\.', $groupId);
        my $finalPath = $mavenArtifactsDir . "/repository";
        for my $pathCounter (@pathFormer) {
            $finalPath = $finalPath . "/" . $pathCounter;
        }
        $finalPath = $finalPath . "/" . $artifactId;
    
        #delete the snapshot tree under the maven directory
        rmtree($finalPath, { verbose => 1, mode => 0711 });
    
        print $!;
    }
}

=head2 _createNewSnapshots

=cut

sub _createNewSnapshots{
    #create new snapshots for each local dependency
    for my $count (@localDevVersions){
        my $dependencyName = $count;
    
        #assuming settings file resides in maven artifacts Dir
        my @mvnExecutorClean = ($mavenDir . "/mvn.bat","clean","-f",$dependencyName . "/pom.xml","--settings",$mavenArtifactsDir . "/" . $settingsFile);
        my @mvnExecutorInstall = ($mavenDir . "/mvn.bat","install","-f",$dependencyName . "/pom.xml","--settings",$mavenArtifactsDir . "/" . $settingsFile);
    
        system(@mvnExecutorClean);
        system(@mvnExecutorInstall);
    }

    #create new snapshot for webApp
    #assuming settings file resides in maven artifacts Dir
    my @mvnExecutorClean = ($mavenDir . "/mvn.bat","clean","-f",$webAppLoc . "/pom.xml","--settings",$mavenArtifactsDir . "/" . $settingsFile);
    my @mvnExecutorInstall = ($mavenDir . "/mvn.bat","install","-f",$webAppLoc . "/pom.xml","--settings",$mavenArtifactsDir . "/" . $settingsFile);

    system(@mvnExecutorClean);
    system(@mvnExecutorInstall);

}

=head2 _hostAndStart

=cut

sub _hostAndStart{
    #hosting webApp in tomcat
    
    my $tomcatPathMaker = _getWebappDirectory();
    my $webappArtifactId = _getArtifactIdOfParent();

    my @finalCmd = ("mkdir", $tomcatPathMaker . "/" . $webappArtifactId);
    system(@finalCmd);
    dircopy($webAppLoc . "/target/" . $webappArtifactId, $tomcatPathMaker . "/" . $webappArtifactId);
    _startTomcat();
}
=head1 AUTHOR

Subhobrata Dey, C<< <sbcd90 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mavenbuilds-tasks-buildwebappswithmaven at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MavenBuilds-Tasks-BuildWebappsWithMaven>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MavenBuilds::Tasks::BuildWebappsWithMaven


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MavenBuilds-Tasks-BuildWebappsWithMaven>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MavenBuilds-Tasks-BuildWebappsWithMaven>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MavenBuilds-Tasks-BuildWebappsWithMaven>

=item * Search CPAN

L<http://search.cpan.org/dist/MavenBuilds-Tasks-BuildWebappsWithMaven/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Subhobrata Dey.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of MavenBuilds::Tasks::BuildWebappsWithMaven

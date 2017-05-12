RPM_PACKAGES="perl perl-devel cpan gcc make libgccjit-devel git"
APT_PACKAGES="build-essential libperl-dev git libgccjit-5-dev"
CPAN_PACKAGES="FFI::Raw Test::Fatal"

TEMPLATES = {
    fedora: [
        "dnf install -y #{RPM_PACKAGES}",
        "cpan install #{CPAN_PACKAGES}",
    ],

    debian: [
        "echo deb http://ftp.debian.org/debian/ testing main contrib non-free > /etc/apt/sources.list.d/testing.list",
        "apt-get update",
        "apt-get -y install #{APT_PACKAGES}",
        "cpan install #{CPAN_PACKAGES}",
    ],
}

def prov(vm, kind, box)
    vm.vm.box = box
    vm.vm.box_check_update = false
    for script in TEMPLATES[kind]
        vm.vm.provision "shell", inline: script
    end
end

Vagrant.configure("2") do |config|
    config.vm.define "f22-64" do |vm|
        prov vm, :fedora, "boxcutter/fedora22"
    end
    config.vm.define "deb8-64" do |vm|
        prov vm, :debian, "boxcutter/debian80"
    end
    config.vm.define "deb8-32" do |vm|
        prov vm, :debian, "boxcutter/debian80-i386"
    end
end

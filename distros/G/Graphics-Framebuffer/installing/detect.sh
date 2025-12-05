#!/bin/bash

# Detects which OS and if it is Linux then it will detect which Linux
# Distribution.
# from http://linuxmafia.com/faq/Admin/release-files.html
#

Green="\033[0;32m"
Color_Off="\033[0m"

OS=`uname -s`
REV=`uname -r`
MACH=`uname -m`

source /etc/lsb-release

# echo $DISTRIB_ID
# echo $DISTRIB_RELEASE
# echo $DISTRIB_CODENAME
# echo $DISTRIB_DESCRIPTION

GetVersionFromFile()
{
    VERSION=`cat $1 | tr "\n" ' ' | sed s/.*VERSION.*=\ // `
}

if [ "${OS}" = "Darwin" ]; then
    OIFS="$IFS"
    IFS=$'\n'
    set `sw_vers` > /dev/null
    DIST=`echo $1 | tr "\n" ' ' | sed 's/ProductName:[ ]*//'`
    VERSION=`echo $2 | tr "\n" ' ' | sed 's/ProductVersion:[ ]*//'`
    BUILD=`echo $3 | tr "\n" ' ' | sed 's/BuildVersion:[ ]*//'`
    OSSTR="${OS} ${DIST} ${REV}(SORRY_NO_PSEUDONAME ${BUILD} ${MACH})"
    IFS="$OIFS"

elif [ "${OS}" = "SunOS" ] ; then
    OS=Solaris
    ARCH=`uname -p` 
    OSSTR="${OS} ${REV}(${ARCH} `uname -v`)"

elif [ "${OS}" = "AIX" ] ; then
    OSSTR="${OS} `oslevel` (`oslevel -r`)"
elif [ "${OS}" = "Linux" ] ; then
    KERNEL=`uname -r`
    if [ -f /etc/redhat-release ] ; then
        DIST='RedHat'
        PSUEDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
        REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
    elif [ -f /etc/SuSE-release ] ; then
        DIST=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
        REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
    elif [ -f /etc/mandrake-release ] ; then
        DIST='Mandrake'
        PSUEDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
        REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
    elif [ -f /etc/debian_version ] ; then
        DIST="Debian `cat /etc/debian_version`"
        REV=""
    elif [ -f /etc/UnitedLinux-release ] ; then
        DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
    fi

    OSSTR="${OS} ${DIST} ${REV}(${PSUEDONAME} ${KERNEL} ${MACH})"

fi

is_arm="NO"

#Distros vars
known_compatible_distros=(
                        "Wifislax"
                        "Kali"
                        "Parrot"
                        "Backbox"
                        "Blackarch"
                        "Cyborg"
                        "Ubuntu"
                        "Debian"
                        "Mint"
                        "SuSE"
                        "CentOS"
                        "Gentoo"
                        "Fedora"
                        "Red Hat"
                        "Arch"
                        "OpenMandriva"
                        "Zorin"
                    )

known_arm_compatible_distros=(
                        "Raspbian"
                        "Parrot arm"
                        "Kali arm"
                        "Debian"
                        "Mint"
                        "Ubuntu"
                    )

#First phase of Linux distro detection based on uname output
function detect_distro_phase1() {

    for i in "${known_compatible_distros[@]}"; do
        uname -a | grep "${i}" -i > /dev/null
        if [ "$?" = "0" ]; then
            distro="${DISTRIB_DESCRIPTION} (${i^} based)"
            break
        fi
    done
}

#Second phase of Linux distro detection based on architecture and version file
function detect_distro_phase2() {

    if [ "${distro}" = "Unknown Linux" ]; then
        if [ -f ${osversionfile_dir}"centos-release" ]; then
            distro="CentOS"
        elif [ -f ${osversionfile_dir}"fedora-release" ]; then
            distro="Fedora"
        elif [ -f ${osversionfile_dir}"gentoo-release" ]; then
            distro="Gentoo"
        elif [ -f ${osversionfile_dir}"openmandriva-release" ]; then
            distro="OpenMandriva"
        elif [ -f ${osversionfile_dir}"redhat-release" ]; then
            distro="Red Hat"
        elif [ -f ${osversionfile_dir}"SuSE-release" ]; then
            distro="SuSE"
        elif [ -f ${osversionfile_dir}"debian_version" ]; then
            distro="Debian"
            if [ -f ${osversionfile_dir}"os-release" ]; then
                extra_os_info=$(cat < ${osversionfile_dir}"os-release" | grep "PRETTY_NAME")
                if [[ "${extra_os_info}" =~ Raspbian ]]; then
                    distro="Raspbian"
                    is_arm="YES"
                elif [[ "${extra_os_info}" =~ Parrot ]]; then
                    distro="Parrot arm"
                    is_arm="YES"
                fi
            fi
        fi
    fi

    detect_arm_architecture
}

#Detect if arm architecture is present on system
function detect_arm_architecture() {

    distro_already_known=0
    uname -m | grep -i "arm" > /dev/null

    if [[ "$?" = "0" ]] && [[ "${distro}" != "Unknown Linux" ]]; then

        for item in "${known_arm_compatible_distros[@]}"; do
            if [ "${distro}" = "${item}" ]; then
                distro_already_known=1
            fi
        done

        if [ ${distro_already_known} -eq 0 ]; then
            distro="${distro} arm"
            is_arm="YES"
        fi
    fi
}

detect_distro_phase1
detect_distro_phase2
###############################################################################
echo "For a comprehensive list, see:"
echo "  https://en.wikipedia.org/wiki/List_of_Linux_distributions"
echo ""
echo "Debian Distributions:"
echo "  * Debian       * Ubuntu              * Kubuntu"
echo "  * Xubuntu      * Element OS          * Edubuntu"
echo "  * Mythbuntu    * Gobuntu             * Eeebuntu"
echo "  * Emmabuntus   * GendBuntu           * Netrunner"
echo "  * OpenGEU      * Pinguy OS           * Poseidon Linux"
echo "  * Sabily       * Trisquel GNULinux   * Ututo"
echo "  * Knoppix      * Damn Small Linux    * Feather Linux"
echo "  * LMDE         * PureOS              * SparkyLinux"
echo "  * BackBox      * Bodhi Linux         * Cub Linux"
echo "  * EasyPeasy    * elementary OS       * Mint"
echo "  * Molinux      * Raspian             * Twister OS"
echo "  * Mint         * Zorin OS"
echo ""
echo "RedHat Distributions"
echo "  * RedHat           * Fedora             * CentOS"
echo "  * ClearOS          * Scientific Linux   * SME"
echo "  * Amazon Linux 2   * Berry Linux        * EnGarde Secure Linux"
echo "  * Funduntu         * Korora             * Linpus Linux"
echo "  * Linux XP         * MeeGo              * Moblin"
echo "  * Qubes OS         * Trustix            * Sugar-on-a-Stick"
echo "  * Aurora           * Berry              * Yellow Dog Linux"
echo ""
echo "Operating System -> ${OSSTR}"
echo -e "Distribution -----> ${Green}${distro}${Color_Off}"
echo "CPU --------------> ${MACH}"

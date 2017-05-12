#!/sbin/runscript

svc_name="HostAPD"

hostapd="/usr/sbin/hostapd"
hostapd_cfg="/etc/hostapd/hostapd.conf"

opts="${opts} reload"

depend() {
	## if necessary change net.wlan0 to your wlan device
	need net.wlan0 logger
}

checkconfig() {
	if [ ! -x "${hostapd}" ]; then
		eerror "HostAPD binary [${hostapd}] missing"
	fi
	if [ ! -r "${hostapd_cfg}" ] ; then
		eerror "HostAPD config [${hostapd_cfg}] missing"
		return 1
	fi
}

start() {
	checkconfig || return 1
	ebegin "Starting ${svc_name}"
	start-stop-daemon --start --quiet --exec "${hostapd}" -- -B "${hostapd_cfg}"
	eend $?
}

stop() {
	checkconfig || return 1
	ebegin "Stopping ${svc_name}"
	start-stop-daemon --stop --quiet --exec "${hostapd}"
	eend $?
}

reload() {
	checkconfig || return 1
	ebegin "Reloading ${svc_name}"
	start-stop-daemon --stop --signal 1 --quiet --exec "${hostapd}"
	eend $?
}

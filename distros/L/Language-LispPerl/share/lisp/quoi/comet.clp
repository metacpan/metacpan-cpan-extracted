(ns quoi

  (. require Language::LispPerl::SocketServer)

  (defn comet-server [host port cb]
    (.Language::LispPerl::SocketServer socket_server host port cb))

  (defn socket-send [s msg]
    (.Language::LispPerl::SocketServer socket_send s msg))

  (defn socket-on-read [s cb]
    (.Language::LispPerl::SocketServer socket_on_read s cb))

  (defn socket-destroy [s]
    (.Language::LispPerl::SocketServer socket_destroy s))

  )

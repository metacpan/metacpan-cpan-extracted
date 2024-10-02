class TcpConnectionData
  attr_reader :ip_address, :port

  def initialize(hostname, port)
    @port = port
    if hostname == "localhost"
      @ip_address = "127.0.0.1"
    else
      begin
        @ip_address = IPSocket.getaddress(hostname)
      rescue SocketError
        raise "Unable to resolve hostname to an IP address."
      end
    end
  end

  def ==(other)
    other.is_a?(TcpConnectionData) && @ip_address == other.ip_address && @port == other.port
  end

  def to_s
    "#{@ip_address}:#{@port}"

  end

  def get_address_bytes
    @ip_address.split(".").map(&:to_i)
  end

  def get_port_bytes
    [@port & 0xFF, @port >> 8]
  end
end
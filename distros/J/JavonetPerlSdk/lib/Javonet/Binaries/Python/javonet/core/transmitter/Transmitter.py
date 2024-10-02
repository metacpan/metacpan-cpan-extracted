from javonet.core.transmitter.TransmitterWrapper import TransmitterWrapper


class Transmitter:

    @staticmethod
    def send_command(message):
        return TransmitterWrapper.send_command(message)

    @staticmethod
    def activate(license_key):
        return TransmitterWrapper.activate(license_key)

    @staticmethod
    def set_config_source(source_path):
        return TransmitterWrapper.set_config_source(source_path)
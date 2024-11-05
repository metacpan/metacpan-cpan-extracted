def callbackFunc(message_byte_array, message_byte_array_len):
    from javonet.core.receiver.Receiver import Receiver
    python_receiver = Receiver()
    if message_byte_array[10] == 11:
        return python_receiver.HeartBeat(message_byte_array, message_byte_array_len)
    else:
        return python_receiver.SendCommand(message_byte_array, message_byte_array_len)

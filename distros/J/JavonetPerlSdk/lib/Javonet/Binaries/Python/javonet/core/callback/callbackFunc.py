def callbackFunc(message_byte_array, message_byte_array_len):
    from javonet.core.receiver.Receiver import Receiver
    python_receiver = Receiver()
    response = python_receiver.HeartBeat(message_byte_array, message_byte_array_len)
    return response
